use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use apps::vmware::vsphere8::custom::api;
use apps::vmware::vsphere8::custom::vim25;


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

sub main {
    #process_test('localhost', 443, 'https', '/v2', 10, 'user', 'pass');
    process_test('localhost', 3000, 'http', undef, 10, 'login', 'password');
    test_vstats_response_is_usable();
    test_vim25_unit_conversion();
    test_vim25_counter_resolution();
    test_vim25_xml_hardening();
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
