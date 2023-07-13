#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package hardware::ups::ees::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_system_status = {
    1  => 'unknown',
    2  => 'normal',
    3  => 'warning',
    4  => 'minor',
    5  => 'major',
    6  => 'critical',
    7  => 'unmanaged',
    8  => 'restricted',
    9  => 'testing',
    10 => 'disabled'
};

my $map_communication_status = {
    1 => 'unknown',
    2 => 'normal',
    3 => 'interrupt'
};

sub status_custom_output {
    my ($self, %options) = @_;

    return sprintf(
        "system status: '%s' - communication status: '%s'",
        $self->{result_values}->{system_status},
        $self->{result_values}->{communication_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 0 }
    ];

    $self->{maps_counters}->{system} = [
        {
            label            => 'status',
            unknown_default  => '%{system_status} =~ /unknown|unmanaged|restricted|testing|disabled/i || %{communication_status} =~ /unknown/i',
            warning_default  => '%{system_status} =~ /warning|minor/i',
            critical_default => '%{system_status} =~ /major|critical/i || %{communication_status} =~ /interrupt/i',
            type             => 2,
            set              => {
                key_values => [
                    { name => 'system_status' },
                    { name => 'communication_status' }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('status_custom_output')
            }
        },
        {
            label => 'voltage', nlabel => 'system.voltage.volt',
            set   => {
                key_values      => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ]
            }
        },
        {
            label => 'current', nlabel => 'system.current.ampere',
            set   => {
                key_values      => [ { name => 'current' } ],
                output_template => 'current: %.2fA',
                perfdatas       => [ { template => '%.2f', unit => 'A' } ]
            }
        },
        {
            label => 'used-capacity', nlabel => 'system.used.capacity.percentage',
            set   => {
                key_values      => [ { name => 'used_capacity' } ],
                output_template => 'used capacity: %.2f%%',
                perfdatas       => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_systemStatus = '.1.3.6.1.4.1.6302.2.1.2.1.0';
    my $oid_systemVoltage = '.1.3.6.1.4.1.6302.2.1.2.2.0';
    my $oid_systemCurrent = '.1.3.6.1.4.1.6302.2.1.2.3.0';
    my $oid_systemUsedCapacity = '.1.3.6.1.4.1.6302.2.1.2.4.0';
    my $oid_psStatusCommunication = '.1.3.6.1.4.1.6302.2.1.2.8.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_systemStatus,
            $oid_systemVoltage,
            $oid_systemCurrent,
            $oid_systemUsedCapacity,
            $oid_psStatusCommunication
        ],
        nothing_quit => 1
    );

    $self->{system} = {
        system_status        => $map_system_status->{$snmp_result->{$oid_systemStatus}},
        communication_status => $map_communication_status->{$snmp_result->{$oid_psStatusCommunication}},
        voltage              => $snmp_result->{$oid_systemVoltage} / 1000,
        current              => $snmp_result->{$oid_systemCurrent} / 1000,
        used_capacity        => $snmp_result->{$oid_systemUsedCapacity}
    };
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{system_status} =~ /unknown|unmanaged|restricted|testing|disabled/i || %{communication_status} =~ /unknown/i').
You can use the following variables: %{system_status}, %{communication_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{system_status} =~ /warning|minor/i').
You can use the following variables: %{system_status}, %{communication_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{system_status} =~ /major|critical/i || %{communication_status} =~ /interrupt/i').
You can use the following variables: %{system_status}, %{communication_status}

=item B<--warning-*> B<--critical-*>

Thresholds: voltage (V), current (A), used-capacity (%)

=back

=cut
