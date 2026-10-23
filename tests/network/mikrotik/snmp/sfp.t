use strict;
use warnings;

package MockOptions;
sub new { bless { extra_arguments => [ ], option_results => {}, default => {}, custom => {} }, shift }
sub add_options { }
sub add_help { }

package MockOutput;
sub new { bless {}, shift }
sub add_option_msg { }
sub output_add { my ($self, %options) = @_; push @{$self->{long}}, $options{long_msg} if defined($options{long_msg}) }
sub use_new_perfdata { }
sub decode { return $_[1] }
sub option_exit { my ($self, %options) = @_; die "option_exit: " . ($options{short_msg} // '') . "\n" }

# Serves the mtxrOpticalTable entries of the 'walk' attribute
package MockSNMP;
sub new { my ($class, %options) = @_; bless { walk => $options{walk}, table_calls => 0, loaded => [] }, $class }
sub get_hostname { 'sfp-switch.example' }
sub get_port { 161 }
sub get_table {
    my ($self, %options) = @_;
    $self->{table_calls}++;
    return { map { $_ => $self->{walk}->{$_} } grep { index($_, $options{oid} . '.') == 0 } keys %{$self->{walk}} };
}
sub load {
    my ($self, %options) = @_;
    foreach my $instance (@{$options{instances}}) {
        push @{$self->{loaded}}, map { $_ . '.' . $instance } @{$options{oids}};
    }
}
sub get_leef {
    my ($self) = @_;
    my $result = { map { $_ => $self->{walk}->{$_} } @{$self->{loaded}} };
    $self->{loaded} = [];
    return $result;
}
sub map_instance {
    my ($self, %options) = @_;
    my $result = {};
    foreach my $name (keys %{$options{mapping}}) {
        my $value = $options{results}->{ $options{mapping}->{$name}->{oid} . '.' . $options{instance} };
        $value = $options{mapping}->{$name}->{map}->{$value} // 'unknown'
            if (defined($value) && defined($options{mapping}->{$name}->{map}));
        $result->{$name} = $value;
    }
    return $result;
}

package main;

# Unit tests of the Mikrotik SFP mode: cache and lock handling, filters and value conversions

use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use network::mikrotik::snmp::mode::sfp;

my $entry = '.1.3.6.1.4.1.14988.1.1.19.1.1';
# index => [ name, rx loss, tx fault, wavelength, temperature, voltage, bias, tx power, rx power, vendor, serial ]
my %modules = (
    2 => [ 'sfp-sfpplus1', 0, 0, 131000, 34, 3290, 21, -6505, -6834, 'VENDOR A', 'SN00000001' ],
    3 => [ 'sfp-sfpplus2', 0, 0, 131000, 46, 3324, 32, -6118, -5047, 'OEM', 'SN00000002' ],
    4 => [ 'sfp-sfpplus3', 1, 0, 155000, 39, 3301, 25, -5512, -40000, 'OEM', 'SN00000003' ]
);

sub build_walk {
    my $walk = {};
    foreach my $index (@_) {
        for my $column (2 .. 12) {
            $walk->{"$entry.$column.$index"} = $modules{$index}->[$column - 2];
        }
    }
    return $walk;
}

my $output = MockOutput->new();
my $mode = network::mikrotik::snmp::mode::sfp->new(options => MockOptions->new(), output => $output);
$mode->{mode} = 'sfp';

# the cache file is kept in memory
my ($cache, $writes) = (undef, 0);
my $statefile = mock 'centreon::plugins::statefile' => (override => [
    read      => sub { my ($self) = @_; $self->{datas} = $cache // {}; return defined($cache) ? 1 : 0 },
    read_from => sub { my ($self, %options) = @_; $self->{datas} = $options{datas} },
    get       => sub { my ($self, %options) = @_; return $self->{datas}->{ $options{name} } },
    write     => sub { my ($self, %options) = @_; $cache = $options{data}; $writes++ }
]);

# another check may hold the lock
my $lock_free = 1;
my $lockfile = mock 'centreon::plugins::lockfile' => (override => [
    try_lock => sub { return $lock_free },
    unlock   => sub { 1 }
]);

sub run_check {
    my (%options) = @_;
    $mode->{option_results} = { reload_cache_time => 180, %{$options{options} // {}} };
    my $snmp = MockSNMP->new(walk => build_walk(@{$options{modules}}));
    $mode->manage_selection(snmp => $snmp);
    return $snmp;
}

subtest 'First check builds the cache' => sub {
    ($cache, $writes, $lock_free) = (undef, 0, 1);
    my $snmp = run_check(modules => [ 2, 3 ]);

    is($snmp->{table_calls}, 1, 'module names walked');
    is($writes, 1, 'cache written');
    is($cache->{sfp}, { 2 => { name => 'sfp-sfpplus1' }, 3 => { name => 'sfp-sfpplus2' } }, 'cache content');
    is([ sort keys %{$mode->{sfp}} ], [ 'sfp-sfpplus1', 'sfp-sfpplus2' ], 'modules checked');
    is($mode->{sfp}->{'sfp-sfpplus1'}, {
        name => 'sfp-sfpplus1', vendor => 'VENDOR A', serial => 'SN00000001', rx_loss => 'false', tx_fault => 'false',
        wavelength => 1310, temperature => 34, voltage => 3.29, bias => 21,
        tx_power_dbm => -6.505, tx_power => within(0.22361, 0.00001),
        rx_power_dbm => -6.834, rx_power => within(0.20730, 0.00001)
    }, 'values converted');
};

subtest 'Valid cache: no walk, new module only seen after reload' => sub {
    my $snmp = run_check(modules => [ 2, 3, 4 ]);

    is($snmp->{table_calls}, 0, 'cache used');
    is([ sort keys %{$mode->{sfp}} ], [ 'sfp-sfpplus1', 'sfp-sfpplus2' ], 'module plugged after the cache is not checked');

    $cache->{last_timestamp} -= 1;
    $snmp = run_check(modules => [ 2, 3, 4 ], options => { reload_cache_time => 0 });
    is($snmp->{table_calls}, 1, 'expired cache reloaded');
    is($mode->{sfp}->{'sfp-sfpplus3'}->{rx_loss}, 'true', 'new module checked');
    is($mode->{sfp}->{'sfp-sfpplus3'}->{rx_power_dbm}, -40, 'receive power of the module without signal');
};

subtest 'Removed module is skipped' => sub {
    $output->{long} = [];
    run_check(modules => [ 2, 3 ]);

    is([ sort keys %{$mode->{sfp}} ], [ 'sfp-sfpplus1', 'sfp-sfpplus2' ], 'removed module skipped');
    like($output->{long}, [ qr/skipping SFP 'sfp-sfpplus3'/ ], 'skip reported in debug');
};

subtest 'Expired cache without the lock is reloaded but not rewritten' => sub {
    ($writes, $lock_free) = (0, 0);
    $cache->{last_timestamp} = time() - 3600;
    my $snmp = run_check(modules => [ 2 ], options => { reload_cache_time => 1 });

    is($snmp->{table_calls}, 0, 'expired cache still used without the lock');
    is($writes, 0, 'cache not rewritten');

    $cache = undef;
    $snmp = run_check(modules => [ 2 ]);
    is($snmp->{table_calls}, 1, 'missing cache built without the lock');
    is($writes, 0, 'cache not written without the lock');
    is([ keys %{$mode->{sfp}} ], [ 'sfp-sfpplus1' ], 'module checked');
    $lock_free = 1;
};

subtest 'Filters' => sub {
    $cache = undef;
    run_check(modules => [ 2, 3, 4 ], options => { include_name => 'sfpplus[12]', exclude_name => 'sfpplus1' });
    is([ keys %{$mode->{sfp}} ], [ 'sfp-sfpplus2' ], 'name filters');

    run_check(modules => [ 2, 3, 4 ], options => { exclude_serial => 'SN0000000[12]' });
    is([ keys %{$mode->{sfp}} ], [ 'sfp-sfpplus3' ], 'serial filter');

    like(dies { run_check(modules => [ 2, 3, 4 ], options => { include_name => 'nothing' }) },
        qr/^option_exit: No SFP module found/, 'no module matches the filters');
};

subtest 'Equipment without SFP module' => sub {
    $cache = undef;
    like(dies { run_check(modules => []) }, qr/^option_exit: Can't construct cache: no SFP module found/, 'empty table');
};

subtest 'dBm to mW' => sub {
    is($mode->dbm_to_milliwatt(dbm => 0), 1, '0 dBm');
    is($mode->dbm_to_milliwatt(dbm => -10), within(0.1, 1e-9), '-10 dBm');
    is($mode->dbm_to_milliwatt(dbm => undef), undef, 'no value');
};

done_testing;
