use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use apps::vmware::vsphere8::custom::api;
use apps::vmware::vsphere8::custom::vim25;
use apps::vmware::vsphere8::custom::rtm;


# Mock options class
{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

{
    package MockOutput;
    sub new { bless {}, shift }
    sub add_option_msg { }
    sub option_exit { }

}

sub process_test {
    my ($hostname, $port, $proto, $url_path, $timeout, $username, $password) = @_;

    # Create mock object
    my $options = MockOptions->new();
    my $output  = MockOutput->new();

    # Add options to the $options hashref
    $options->{hostname}    = $hostname;
    $options->{port}        = $port;
    $options->{proto}       = $proto;
    $options->{timeout}     = $timeout;
    $options->{username}    = $username;
    $options->{password}    = $password;

    # Test object creation
    my $api;
    eval {
        $api = apps::vmware::vsphere8::custom::api->new(
            options => $options,
            output => $output
        );
    };
    ok(!$@, 'Object creation without errors');

    # Test if the object is blessed correctly
    is(ref($api), 'apps::vmware::vsphere8::custom::api', 'Object is of correct class');

    # Test if the object has the expected attributes
    can_ok($api, qw(new set_options check_options));

    $api->set_options(option_results => $options);
    # Verify that option_results is set correctly
    is($api->{option_results}, $options, 'option_results set correctly');

    # Test check_options method
    eval { $api->check_options(option_results => $options) };
    ok(!$@, 'check_options method executed without errors');

    is($api->{hostname},    $hostname,  'hostname set correctly');
    is($api->{port},        defined($port)      ? $port     : 443,      'port set correctly');
    is($api->{proto},       defined($proto)     ? $proto    : 'https',  'proto set correctly');
    is($api->{timeout},     defined($timeout)   ? $timeout  : 10,       'timeout set correctly');
    is($api->{username},    defined($username)  ? $username : '',       'username set correctly');
    is($api->{password},    defined($password)  ? $password : '',       'password set correctly');

}

# Output stub that turns option_exit into a die, so the message can be asserted.
{
    package ExitingOutput;
    sub new { bless {}, shift }
    sub add_option_msg { }
    sub option_exit { my ($self, %options) = @_; die $options{short_msg} . "\n"; }
}

{
    package MockHttp;
    sub new { my ($class, $code) = @_; return bless { code => $code }, $class; }
    sub get_code { return $_[0]->{code} }
}

# The vStats API is removed in vSphere 9.1: the plugin must detect it instead of
# silently collecting nothing. See vstats_response_is_usable() in the custom API package.
sub test_vstats_response_is_usable {
    my $api = apps::vmware::vsphere8::custom::api->new(
        options => MockOptions->new(),
        output  => ExitingOutput->new()
    );
    $api->{hostname} = 'vcenter.example.tld';
    $api->{http}     = MockHttp->new(404);

    # vSphere 8.0 to 9.0: the collection is present, even when empty
    is($api->vstats_response_is_usable(response => { acq_specs => [] }), 1,
        'empty but well-formed acq_specs collection is usable');
    is($api->vstats_response_is_usable(response => { acq_specs => [ { id => '225' } ], next => 42 }), 1,
        'populated acq_specs collection is usable');

    # vSphere 9.1: the vStats backend is no longer registered
    for my $case (
        [ 'empty body',           {} ],
        [ 'error body',           { error_type => 'NOT_FOUND', messages => [] } ],
        [ 'non-hash body',        'Not Found' ],
        [ 'undefined body',       undef ],
        [ 'acq_specs not a list', { acq_specs => 'nope' } ]
    ) {
        my ($label, $response) = @$case;
        is($api->vstats_response_is_usable(response => $response), 0,
            "vStats is detected as unusable ($label)");
    }

    my $message = $api->vstats_unavailable_message();
    like($message, qr/removed in vSphere 9\.1/,  'the message states the 9.1 removal');
    like($message, qr/vcenter\.example\.tld/,   'the message names the faulty vCenter');
    like($message, qr/404/,                      'the message reports the HTTP code');
    like($message, qr/--metrics-source=vim25/,   'the message points to the vim25 fallback');
}

# The vim25 fallback must never report a value it could not convert safely.
sub test_vim25_unit_conversion {
    my $vim25 = apps::vmware::vsphere8::custom::vim25->new(
        noptions => 1,
        options  => MockOptions->new(),
        output   => ExitingOutput->new(),
        hostname => 'vcenter.example.tld'
    );

    # PerformanceManager reports memory in kiloBytes, the modes expect MB
    is($vim25->convert_unit(value => 1048576, from => 'kiloBytes', to => 'MB', cid => 'mem.capacity.usable.HOST'),
        1024, 'kiloBytes are converted to MB');
    # ... CPU in megaHertz while the host modes expect kHz
    is($vim25->convert_unit(value => 3200, from => 'megaHertz', to => 'kHz', cid => 'cpu.capacity.usage.HOST'),
        3200000, 'megaHertz are converted to kHz');
    # the vim25 'percent' unit is expressed in hundredths of a percent
    is($vim25->convert_unit(value => 4500, from => 'percent', to => 'pct', cid => 'cpu.capacity.contention.HOST'),
        45, 'hundredths of a percent are converted to percent');
    # an identity conversion must not alter the value
    is($vim25->convert_unit(value => 210, from => 'watt', to => 'W', cid => 'power.capacity.usage.HOST'),
        210, 'identical units leave the value untouched');

    # converting across dimensions would silently report a wrong metric
    like(dies { $vim25->convert_unit(value => 1, from => 'kiloBytes', to => 'kHz', cid => 'bogus.HOST') },
        qr/Refusing to report a wrong value/, 'a cross-dimension conversion is refused');
    like(dies { $vim25->convert_unit(value => 1, from => 'parsecs', to => 'kHz', cid => 'bogus.HOST') },
        qr/unknown unit/, 'an unknown unit is refused');
}

# Counter ids keep their vStats naming and are resolved against the vCenter catalogue.
sub test_vim25_counter_resolution {
    my $vim25 = apps::vmware::vsphere8::custom::vim25->new(
        noptions => 1,
        options  => MockOptions->new(),
        output   => ExitingOutput->new(),
        hostname => 'vcenter.example.tld'
    );

    is($vim25->entity_type(rsrc_id => 'host-35'), 'HostSystem',     'a host id maps to HostSystem');
    is($vim25->entity_type(rsrc_id => 'vm-42'),   'VirtualMachine', 'a vm id maps to VirtualMachine');
    like(dies { $vim25->entity_type(rsrc_id => 'datastore') },
        qr/cannot determine the managed object type/, 'an unparsable resource id is refused');

    # exact name advertised by the vCenter
    $vim25->{catalogue} = { 'cpu.capacity.usage.average' => { key => 6, unit => 'kiloHertz' } };
    is($vim25->resolve_counter(cid => 'cpu.capacity.usage.HOST')->{key}, 6,
        'a counter advertised under its vStats name is resolved directly');

    # historical name only: the alias table takes over
    $vim25->{catalogue} = { 'cpu.usagemhz.average' => { key => 11, unit => 'megaHertz' } };
    is($vim25->resolve_counter(cid => 'cpu.capacity.usage.HOST')->{key}, 11,
        'a counter advertised under its historical name is resolved through the alias table');

    # neither: the plugin says so instead of reporting nothing
    $vim25->{catalogue} = { 'net.usage.average' => { key => 90, unit => 'kiloBytesPerSecond' } };
    like(dies { $vim25->resolve_counter(cid => 'cpu.capacity.usage.HOST') },
        qr/has no PerformanceManager equivalent/, 'an unmappable counter raises an explicit error');
}

# vim25 responses are untrusted input: the parser must not resolve external entities.
sub test_vim25_xml_hardening {
    my $vim25 = apps::vmware::vsphere8::custom::vim25->new(
        noptions => 1,
        options  => MockOptions->new(),
        output   => ExitingOutput->new(),
        hostname => 'vcenter.example.tld'
    );

    my $secret = "$FindBin::RealBin/xxe_canary.txt";
    open(my $fh, '>', $secret) or die "cannot write the XXE canary: $!";
    print $fh 'CANARY_SHOULD_NEVER_BE_READ';
    close($fh);

    my $xxe = qq{<?xml version="1.0"?>}
        . qq{<!DOCTYPE root [<!ENTITY leak SYSTEM "file://$secret">]>}
        . qq{<root xmlns="urn:vim25"><val>&leak;</val></root>};

    my $doc = $vim25->parse_xml(content => $xxe);
    my $parsed = defined($doc) ? $doc->documentElement()->textContent() : '';
    unlink($secret);

    unlike($parsed, qr/CANARY_SHOULD_NEVER_BE_READ/,
        'an external entity is not resolved when parsing a vim25 response');

    # a billion-laughs payload must not be expanded either
    my $bomb = q{<?xml version="1.0"?>}
        . q{<!DOCTYPE root [<!ENTITY a "aaaaaaaaaa"><!ENTITY b "&a;&a;&a;&a;&a;&a;&a;&a;&a;&a;">}
        . q{<!ENTITY c "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">]>}
        . q{<root xmlns="urn:vim25"><val>&c;</val></root>};
    my $bomb_doc = $vim25->parse_xml(content => $bomb);
    my $expanded = defined($bomb_doc) ? $bomb_doc->documentElement()->textContent() : '';
    ok(length($expanded) < 1000, 'nested entities are not expanded when parsing a vim25 response');

    # a malformed payload is reported as unparsable rather than dying
    is($vim25->parse_xml(content => '<not-xml'), undef, 'a malformed payload returns undef');
    is($vim25->parse_xml(content => ''),         undef, 'an empty payload returns undef');
}

# A statefile written before this fix holds an empty acq_specs list. Trusting it would
# short-circuit the vStats detection and keep an already-affected poller silent, which
# is the very population the fix targets. Such a cache must behave as a cache miss.
{
    package MockCache;
    sub new { my ($class, %o) = @_; return bless { %o, writes => [] }, $class; }
    sub read { return $_[0]->{readable} ? 1 : 0 }
    sub get { return $_[0]->{content} }
    sub write { my ($self, %o) = @_; push @{$self->{writes}}, $o{data}; return 1; }
    sub check_options { }
}

sub build_api_with_cache {
    my (%options) = @_;

    my $api = apps::vmware::vsphere8::custom::api->new(
        options => MockOptions->new(),
        output  => ExitingOutput->new()
    );
    $api->{hostname}        = 'vcenter.example.tld';
    $api->{port}            = 443;
    $api->{username}        = 'svc-centreon';
    $api->{http}            = MockHttp->new($options{http_code} // 404);
    $api->{acq_specs_cache} = MockCache->new(readable => 1, content => $options{cached});
    # what a vCenter 9.1 answers once the vStats backend is unregistered
    $api->{mocked_response} = $options{response} // {};
    no warnings 'redefine';
    local *apps::vmware::vsphere8::custom::api::request_api = sub { return $_[0]->{mocked_response} };
    return ($api, $api->get_all_acq_specs(rsrc_id => 'host-35'));
}

sub test_poisoned_cache_is_ignored {
    # the exact statefile a 9.1 vCenter left behind before the fix
    my ($api, $result) = build_api_with_cache(cached => []);
    is($result, undef, 'an empty cached list does not short-circuit the vStats detection');
    is($api->{vstats_unavailable}, 1, 'the vStats removal is detected despite the poisoned cache');
    is(scalar @{$api->{acq_specs_cache}->{writes}}, 0, 'nothing is written back when vStats is unusable');

    # a corrupted statefile must behave the same way
    for my $case ([ 'undef', undef ], [ 'not a list', 'garbage' ], [ 'hash', {} ]) {
        my ($label, $content) = @$case;
        my (undef, $res) = build_api_with_cache(cached => $content);
        is($res, undef, "a malformed cached value ($label) is treated as a cache miss");
    }

    # a populated cache is still trusted, and no request is made
    my $spec = { counters => { cid_mid => { cid => 'cpu.capacity.usage.HOST' } },
                 resources => [ { id_value => 'host-35', predicate => 'EQUAL', scheme => 'moid' } ],
                 status => 'ENABLED', expiration => time() + 86400, id => '225' };
    my ($cached_api, $cached_result) = build_api_with_cache(cached => [ $spec ]);
    is(ref($cached_result), 'ARRAY',            'a populated cache is still used');
    is(scalar @$cached_result, 1,               'the cached specification is returned as is');
    ok(!$cached_api->{vstats_unavailable},      'a populated cache does not trigger the detection');

    # a healthy vCenter answer is cached, an empty one is not
    my ($healthy, $healthy_result) = build_api_with_cache(
        cached    => [],
        http_code => 200,
        response  => { acq_specs => [ $spec ] }
    );
    is(scalar @$healthy_result, 1, 'the specification returned by the API is collected');
    is(scalar @{$healthy->{acq_specs_cache}->{writes}}, 1, 'a non-empty result is written to the cache');

    my ($empty, $empty_result) = build_api_with_cache(
        cached    => [],
        http_code => 200,
        response  => { acq_specs => [] }
    );
    is(scalar @$empty_result, 0, 'an empty but well-formed API answer is not an error');
    is(scalar @{$empty->{acq_specs_cache}->{writes}}, 0, 'an empty result is not persisted');
}

# Creating or extending a specification makes the stored list obsolete: it must not be
# persisted afterwards, otherwise a partial snapshot makes every later run re-create the
# specifications missing from it.
sub test_acq_specs_invalidation {
    my $api = apps::vmware::vsphere8::custom::api->new(
        options => MockOptions->new(),
        output  => ExitingOutput->new()
    );
    $api->{all_acq_specs} = [ { id => '225' } ];

    $api->invalidate_acq_specs();
    ok(!defined($api->{all_acq_specs}), 'the stored list is dropped on invalidation');
    is($api->{acq_specs_stale}, 1,      'the list is flagged as stale on invalidation');
}

# The Real-Time Metrics source targets VCF Operations, not the vCenter, and must never
# report a value it could not resolve or convert safely.
sub build_rtm {
    my (%options) = @_;

    my $rtm = apps::vmware::vsphere8::custom::rtm->new(
        noptions => 1,
        options  => MockOptions->new(),
        output   => ExitingOutput->new()
    );
    $rtm->set_options(option_results => {
        rtm_hostname => 'vcfops.example.tld',
        rtm_username => 'svc-centreon',
        rtm_password => 's3cret',
        %options
    });

    return $rtm;
}

sub test_rtm_options {
    my $rtm = build_rtm();
    $rtm->check_options();
    is($rtm->{hostname},  'vcfops.example.tld',   'the VCF Operations address is taken from --rtm-hostname');
    is($rtm->{base_path}, '/data-query-service',  'the base path defaults to the data-query-service');
    is($rtm->{port},      443,                    'the port defaults to 443');

    # a trailing slash would produce a double slash in every query
    my $trailing = build_rtm(rtm_base_path => '/data-query-service/');
    $trailing->check_options();
    is($trailing->{base_path}, '/data-query-service', 'a trailing slash is stripped from the base path');

    # the source cannot silently fall back on the vCenter credentials
    for my $missing (qw/rtm_hostname rtm_username rtm_password/) {
        my $incomplete = build_rtm($missing => undef);
        (my $option = $missing) =~ tr/_/-/;
        like(dies { $incomplete->check_options() }, qr/needs the --\Q$option\E option/,
            "--$option is required by the Real-Time Metrics source");
    }

    my $mapped = build_rtm(rtm_metric_map => [ 'cpu.capacity.usage.HOST=custom_metric' ]);
    $mapped->check_options();
    is($mapped->{metric_overrides}->{'cpu.capacity.usage.HOST'}, 'custom_metric',
        'a --rtm-metric-map entry is parsed');

    my $malformed = build_rtm(rtm_metric_map => [ 'no_equal_sign' ]);
    like(dies { $malformed->check_options() }, qr/Malformed --rtm-metric-map/,
        'a malformed --rtm-metric-map entry is refused');
}

sub test_rtm_metric_resolution {
    my $rtm = build_rtm();
    $rtm->check_options();
    $rtm->{catalogue} = { 'vcenter_host_cpu_capacity_usage_megahertz' => 1, 'custom_metric' => 1 };

    my $resolved = $rtm->resolve_metric(cid => 'cpu.capacity.usage.HOST');
    is($resolved->{metric}, 'vcenter_host_cpu_capacity_usage_megahertz', 'a known counter resolves to its metric');
    is($resolved->{target}, 'kHz',                                      'the target unit of the host CPU counter is kHz');

    # a metric absent from the appliance catalogue must not be queried blindly
    $rtm->{catalogue} = { 'something_else' => 1 };
    like(dies { $rtm->resolve_metric(cid => 'cpu.capacity.usage.HOST') },
        qr/is not advertised by the Real-Time Metrics API/, 'a metric missing from the catalogue is refused');

    # an unknown counter tells the user how to map it
    like(dies { $rtm->resolve_metric(cid => 'made.up.counter.HOST') },
        qr/--rtm-metric-map/, 'an unmapped counter points at --rtm-metric-map');

    # an override wins, and must not corrupt the shared mapping table
    my $overridden = build_rtm(rtm_metric_map => [ 'cpu.capacity.usage.HOST=custom_metric' ]);
    $overridden->check_options();
    $overridden->{catalogue} = { 'custom_metric' => 1 };
    is($overridden->resolve_metric(cid => 'cpu.capacity.usage.HOST')->{metric}, 'custom_metric',
        'an override replaces the metric name');

    my $untouched = build_rtm();
    $untouched->check_options();
    $untouched->{catalogue} = { 'vcenter_host_cpu_capacity_usage_megahertz' => 1 };
    is($untouched->resolve_metric(cid => 'cpu.capacity.usage.HOST')->{metric},
        'vcenter_host_cpu_capacity_usage_megahertz', 'the override did not leak into the package mapping');
}

sub test_rtm_unit_conversion {
    my $rtm = build_rtm();
    $rtm->check_options();

    is($rtm->convert_unit(value => 3200, from => 'megahertz', to => 'kHz', cid => 'cpu.capacity.usage.HOST'),
        3200000, 'megahertz are converted to kHz');
    is($rtm->convert_unit(value => 1048576, from => 'kilobytes', to => 'MB', cid => 'mem.capacity.usable.HOST'),
        1024, 'kilobytes are converted to MB');
    # a ratio published as 0..1 has to become a percentage
    is($rtm->convert_unit(value => 0.45, from => 'ratio', to => 'pct', cid => 'cpu.capacity.contention.HOST'),
        45, 'a ratio is converted to a percentage');
    is($rtm->convert_unit(value => 210, from => 'watts', to => 'W', cid => 'power.capacity.usage.HOST'),
        210, 'identical units leave the value untouched');

    like(dies { $rtm->convert_unit(value => 1, from => 'kilobytes', to => 'kHz', cid => 'bogus.HOST') },
        qr/Refusing to report a wrong value/, 'a cross-dimension conversion is refused');
    like(dies { $rtm->convert_unit(value => 1, from => 'furlongs', to => 'kHz', cid => 'bogus.HOST') },
        qr/Unknown unit/, 'an unknown unit is refused');
}

sub test_rtm_label_escaping {
    # a resource id is injected into a PromQL selector and must stay quoted
    is(apps::vmware::vsphere8::custom::rtm::escape_label_value('host-35'), 'host-35',
        'a plain resource id is left untouched');
    is(apps::vmware::vsphere8::custom::rtm::escape_label_value('a"b'), 'a\\"b',
        'a double quote is escaped in a label value');
    is(apps::vmware::vsphere8::custom::rtm::escape_label_value('a\\b'), 'a\\\\b',
        'a backslash is escaped in a label value');
    is(apps::vmware::vsphere8::custom::rtm::escape_label_value(undef), '',
        'an undefined value becomes an empty string');
}

sub main {
    #process_test('localhost', 443, 'https', '/v2', 10, 'user', 'pass');
    process_test('localhost', 3000, 'http', undef, 10, 'login', 'password');
    test_vstats_response_is_usable();
    test_vim25_unit_conversion();
    test_vim25_counter_resolution();
    test_vim25_xml_hardening();
    test_poisoned_cache_is_ignored();
    test_acq_specs_invalidation();
    test_rtm_options();
    test_rtm_metric_resolution();
    test_rtm_unit_conversion();
    test_rtm_label_escaping();
}

main();

done_testing();


__END__



# Test check_options method with missing username
$option_results = {
    hostname => 'localhost',
    port => 443,
    proto => 'https',
    url_path => '/v2',
    timeout => 10,
    password => 'pass'
};
$api->set_options(option_results => $option_results);
eval { $api->check_options() };
like($@, qr/Need to specify --username option/, 'Missing username handled correctly');

# Test check_options method with missing password
$option_results = {
    hostname => 'localhost',
    port => 443,
    proto => 'https',
    url_path => '/v2',
    timeout => 10,
    username => 'user'
};
$api->set_options(option_results => $option_results);
eval { $api->check_options() };
like($@, qr/Need to specify --password option/, 'Missing password handled correctly');


done_testing();
