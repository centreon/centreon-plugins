#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package centreon::common::cisco::standard::snmp::mode::portsecurity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'port security: %s%s, status: %s, violation action: %s',
        $self->{result_values}->{port_security},
        $self->{result_values}->{expected_port_security} ne '' ?
            ' (expected: ' . $self->{result_values}->{expected_port_security} . ')' : '',
        $self->{result_values}->{status},
        $self->{result_values}->{violation_action}
    );
}

sub custom_mac_output {
    my ($self, %options) = @_;

    return sprintf(
        'secure MAC addresses: %s/%s',
        $self->{result_values}->{secure_mac},
        $self->{result_values}->{max_secure_mac}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_interface_output',
          message_multiple => 'All port security interfaces are ok', sort_method => 'num', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{status} eq "shutdown"',
            critical_default => '%{expected_port_security} ne "" and %{port_security} ne %{expected_port_security}',
            set => {
                key_values => [
                    { name => 'port_security' }, { name => 'expected_port_security' }, { name => 'status' },
                    { name => 'violation_action' }, { name => 'admin_status' }, { name => 'oper_status' },
                    { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'secure-mac-addresses', nlabel => 'interface.portsecurity.secure.mac.addresses.count', set => {
                key_values => [ { name => 'secure_mac' }, { name => 'max_secure_mac' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_mac_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'max_secure_mac', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'violations', nlabel => 'interface.portsecurity.violations.count', set => {
                key_values => [ { name => 'violations', diff => 1 }, { name => 'display' } ],
                output_template => 'violations: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-interface:s'      => { name => 'include_interface', default => '' },
        'exclude-interface:s'      => { name => 'exclude_interface', default => '' },
        'oid-display:s'            => {
            name => 'oid_display',
            default => 'ifName',
            is_in => [ 'ifName', 'ifDescr', 'ifAlias' ],
            error_message => "Option --oid-display must be 'ifName', 'ifDescr' or 'ifAlias'."
        },
        'expected-port-security:s' => {
            name => 'expected_port_security',
            default => '',
            is_in => [ 'enabled', 'disabled' ],
            error_message => "Option --expected-port-security must be 'enabled', 'disabled' or empty."
        }
    });

    return $self;
}

my $map_truth = { 1 => 'enabled', 2 => 'disabled' };
my $map_status = { 1 => 'secureup', 2 => 'securedown', 3 => 'shutdown' };
my $map_violation_action = { 1 => 'shutdown', 2 => 'dropNotify', 3 => 'drop' };
my $map_admin_status = { 1 => 'up', 2 => 'down', 3 => 'testing' };
my $map_oper_status = {
    1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown',
    5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown'
};

# CISCO-PORT-SECURITY-MIB cpsIfConfigEntry
my $oid_cpsIfConfigEntry = '.1.3.6.1.4.1.9.9.315.1.2.1.1';
my $mapping_cps = {
    port_security    => { oid => $oid_cpsIfConfigEntry . '.1', map => $map_truth },           # cpsIfPortSecurityEnable
    status           => { oid => $oid_cpsIfConfigEntry . '.2', map => $map_status },          # cpsIfPortSecurityStatus
    max_secure_mac   => { oid => $oid_cpsIfConfigEntry . '.3' },                              # cpsIfMaxSecureMacAddr
    secure_mac       => { oid => $oid_cpsIfConfigEntry . '.4' },                              # cpsIfCurrentSecureMacAddrCount
    violation_action => { oid => $oid_cpsIfConfigEntry . '.8', map => $map_violation_action }, # cpsIfViolationAction
    violations       => { oid => $oid_cpsIfConfigEntry . '.9' }                               # cpsIfViolationCount
};

# IF-MIB
my $mapping_if = {
    ifDescr      => { oid => '.1.3.6.1.2.1.2.2.1.2' },
    admin_status => { oid => '.1.3.6.1.2.1.2.2.1.7', map => $map_admin_status }, # ifAdminStatus
    oper_status  => { oid => '.1.3.6.1.2.1.2.2.1.8', map => $map_oper_status },  # ifOperStatus
    ifName       => { oid => '.1.3.6.1.2.1.31.1.1.1.1' },
    ifAlias      => { oid => '.1.3.6.1.2.1.31.1.1.1.18' }
};

sub get_port_security {
    my (%options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_cpsIfConfigEntry,
        start => $mapping_cps->{port_security}->{oid},
        end => $mapping_cps->{violations}->{oid},
        nothing_quit => 1
    );

    my @instances = map { /^$mapping_cps->{port_security}->{oid}\.(\d+)$/ ? $1 : () } keys %$snmp_result;
    return {} unless @instances;

    $options{snmp}->load(oids => [ map { $_->{oid} } values %$mapping_if ], instances => \@instances, instance_regexp => '^(.*)$');
    my $snmp_if = $options{snmp}->get_leef();

    my $results = {};
    foreach my $instance (@instances) {
        my $cps = $options{snmp}->map_instance(mapping => $mapping_cps, results => $snmp_result, instance => $instance);
        my $if = $options{snmp}->map_instance(mapping => $mapping_if, results => $snmp_if, instance => $instance);
        $results->{$instance} = {
            %$cps,
            index        => $instance,
            name         => $if->{ifName} // '',
            description  => $if->{ifDescr} // '',
            alias        => $if->{ifAlias} // '',
            admin_status => $if->{admin_status} // '',
            oper_status  => $if->{oper_status} // ''
        };
    }

    return $results;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = get_port_security(snmp => $options{snmp});
    # an empty --oid-display (empty macro) falls back to ifName
    my $attribute = { ifName => 'name', ifDescr => 'description', ifAlias => 'alias' }->{$self->{option_results}->{oid_display} || 'ifName'};

    $self->{interfaces} = {};
    foreach my $instance (keys %$results) {
        my $result = $results->{$instance};
        my $display = $result->{$attribute} ne '' ? $result->{$attribute} : $instance;

        next if is_excluded($display, $self->{option_results}->{include_interface}, $self->{option_results}->{exclude_interface}, output => $self->{output});

        $self->{interfaces}->{$instance} = {
            display                => $display,
            port_security          => $result->{port_security},
            expected_port_security => $self->{option_results}->{expected_port_security},
            status                 => $result->{status},
            violation_action       => $result->{violation_action},
            admin_status           => $result->{admin_status},
            oper_status            => $result->{oper_status},
            secure_mac             => $result->{secure_mac},
            max_secure_mac         => $result->{max_secure_mac},
            violations             => $result->{violations}
        };
    }

    $self->{output}->option_exit(short_msg => 'No interface with port security found.')
        unless keys %{$self->{interfaces}};

    $self->{cache_name} = 'cisco_standard_' . $self->{mode} . '_' . sha256_hex(
        $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        $self->{option_results}->{oid_display} . '_' .
        $self->{option_results}->{include_interface} . '_' . $self->{option_results}->{exclude_interface}
    );
}

1;

__END__

=head1 MODE

Check the port security of the interfaces (CISCO-PORT-SECURITY-MIB).

The current port security state (C<enabled> or C<disabled>) can be compared with a reference value
given with C<--expected-port-security>: when they differ, the check returns a critical status.
To accept a new state, update the reference value.

=over 8

=item B<--include-interface>

Filter interfaces by name (can be a regexp). The name is the one selected with C<--oid-display>.

=item B<--exclude-interface>

Exclude interfaces by name (can be a regexp). The name is the one selected with C<--oid-display>.

=item B<--oid-display>

Choose the interface name to display and filter on: C<ifName>, C<ifDescr> or C<ifAlias> (default: C<ifName>).

=item B<--expected-port-security>

Expected port security state: C<enabled> or C<disabled>. Leave it empty to skip the comparison.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<%{status} eq "shutdown">).
You can use the following variables: C<%{port_security}>, C<%{expected_port_security}>, C<%{status}>,
C<%{violation_action}>, C<%{admin_status}>, C<%{oper_status}>, C<%{display}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL
(default: C<%{expected_port_security} ne "" and %{port_security} ne %{expected_port_security}>).
You can use the following variables: C<%{port_security}>, C<%{expected_port_security}>, C<%{status}>,
C<%{violation_action}>, C<%{admin_status}>, C<%{oper_status}>, C<%{display}>.

=item B<--warning-secure-mac-addresses>

Threshold for the number of secure MAC addresses.

=item B<--critical-secure-mac-addresses>

Threshold for the number of secure MAC addresses.

=item B<--warning-violations>

Threshold for the number of security violations since the last check.

=item B<--critical-violations>

Threshold for the number of security violations since the last check.

=back

=cut
