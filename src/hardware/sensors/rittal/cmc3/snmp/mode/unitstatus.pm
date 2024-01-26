#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::sensors::rittal::cmc3::snmp::mode::unitstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_unit_status = {
    1 => 'OK',
    2 => 'failed',
    3 => 'overload'
};

my $map_overall_device_status = {
    1 => 'ok',
    2 => 'warning',
    3 => 'alarm',
    4 => 'detected',
    5 => 'lost',
    6 => 'changed',
    7 => 'update'
};

my $map_unit_mode = {
    1  => 'local init ini progress',
    2  => 'start local system first time',
    3  => 'first start delay',
    4  => 'restart bus system, reread configuration',
    5  => 'locally online',
    6  => 'collect all slaves at the bus',
    7  => 'reorganize bus',
    8  => 'up and running',
    9  => 'prepare for sensor upgrade',
    10 => 'upgrade sensors',
    11 => 'gentle termination',
};

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Unit status: %s - Unit mode: %s - Overall device status: %s [available devices: %d]",
        $self->{result_values}->{unit_status},
        $self->{result_values}->{mode},
        $self->{result_values}->{overall_device_status},
        $self->{result_values}->{available_devices}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [ { name => 'status', type => 0 } ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            unknown_default  => '%{overall_device_status} =~ /detected|lost|changed|update/i',
            warning_default  => '%{unit_status} =~ /overload/i || %{overall_device_status} =~ /warning/i',
            critical_default => '%{unit_status} =~ /failed/i || %{overall_device_status} =~ /alarm/i',
            type             => 2,
            set              => {
                key_values                     => [
                    { name => 'unit_status' },
                    { name => 'overall_device_status' },
                    { name => 'mode' },
                    { name => 'available_devices' }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('custom_status_output')
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

    my $oid_cmcIIIUnitStatus = '.1.3.6.1.4.1.2606.7.2.1.0';
    my $oid_cmcIIIUnitMode = '.1.3.6.1.4.1.2606.7.2.13.0';
    my $oid_cmcIIIOverallDevStatus = '.1.3.6.1.4.1.2606.7.4.1.1.1.0';
    my $oid_cmcIIINumberOfDevs = '.1.3.6.1.4.1.2606.7.4.1.1.2.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_cmcIIIUnitStatus,
            $oid_cmcIIIUnitMode,
            $oid_cmcIIIOverallDevStatus,
            $oid_cmcIIINumberOfDevs
        ],
        nothing_quit => 1
    );

    $self->{status} = {
        unit_status           => $map_unit_status->{ $snmp_result->{$oid_cmcIIIUnitStatus} },
        overall_device_status => $map_overall_device_status->{ $snmp_result->{$oid_cmcIIIOverallDevStatus} },
        mode                  => $map_unit_mode->{ $snmp_result->{$oid_cmcIIIUnitMode} },
        available_devices     => $snmp_result->{$oid_cmcIIINumberOfDevs}
    };
}

1;

__END__

=head1 MODE

Check unit status

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{overall_device_status} =~ /detected|lost|changed|update/i').
You can use the following variables: %{unit_status}, %{overall_device_status}, %{mode}, %{available_devices}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{unit_status} =~ /overload/i || %{overall_device_status} =~ /warning/i').
You can use the following variables: %{unit_status}, %{overall_device_status}, %{mode}, %{available_devices}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{unit_status} =~ /failed/i || %{overall_device_status} =~ /alarm/i').
You can use the following variables: %{unit_status}, %{overall_device_status}, %{mode}, %{available_devices}

=back

=cut
