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

package hardware::devices::barco::cs::restapi::mode::device;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_device_status_output {
    my ($self, %options) = @_;
    
    return sprintf('status: %s', $self->{result_values}->{status});
}

sub custom_process_status_output {
    my ($self, %options) = @_;
    
    return sprintf('status is %s', $self->{result_values}->{status});
}

sub custom_cpu_temp_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'C',
        instances => 'cpu',
        value => $self->{result_values}->{cpu},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_pcie_temp_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'C',
        instances => 'pcie',
        value => $self->{result_values}->{pcie},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_sio_temp_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'C',
        instances => 'sio',
        value => $self->{result_values}->{sio},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_cpu_fan_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'rpm',
        instances => 'cpu',
        value => $self->{result_values}->{cpu},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return 'checking device';
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return 'temperature ';
}

sub prefix_process_output {
    my ($self, %options) = @_;

    return "process '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'device', type => 3, cb_long_output => 'device_long_output', indent_long_output => '    ',
            group => [
                { name => 'status', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'temperature', type => 0, cb_prefix_output => 'prefix_temperature_output', display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'fan', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'processes', type => 1, display_long => 1, display_short => 0, cb_prefix_output => 'prefix_process_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{status} = [
        {
            label => 'device-status',
            type => 2,
            warning_default => '%{status} =~ /warning/',
            critical_default => '%{status} =~ /error/',
            set => {
                key_values => [ { name => 'status' }, ],
                closure_custom_output => $self->can('custom_device_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'cpu-temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'cpu %s C',
                closure_custom_perfdata => $self->can('custom_cpu_temp_perfdata')
            }
        },
        { label => 'pcie-temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'pcie' } ],
                output_template => 'pcie %s C',
                closure_custom_perfdata => $self->can('custom_pcie_temp_perfdata')
            }
        },
        { label => 'sio-temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'sio' } ],
                output_template => 'sio %s C',
                closure_custom_perfdata => $self->can('custom_sio_temp_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{fan} = [
        { label => 'cpu-fanspeed', nlabel => 'hardware.fan.speed.rpm', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'cpu fan speed %s rpm',
                closure_custom_perfdata => $self->can('custom_cpu_fan_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{processes} = [
        {
            label => 'process-status', type => 2,
            set => {
                key_values => [ { name => 'name' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_process_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_status = {
        0 => 'ok', 1 => 'warning', 2 => 'error'
    };
    my $versions = $options{custom}->request_api(endpoint => '/SupportedVersions');
    my $version = 'v1.0';
    foreach (@{$versions->{data}->{value}}) {
        $version = 'v1.11' if ($_ eq 'v1.11');
    }

    my $device_status = $options{custom}->request_api(endpoint => '/v1.0/DeviceInfo/Status');
    my $sensors = $options{custom}->request_api(endpoint => '/' . $version . '/DeviceInfo/Sensors');
    my $processes = $options{custom}->request_api(endpoint => '/v1.0/DeviceInfo/Processes/ProcessTable');

    $self->{output}->output_add(short_msg => 'device is ok');

    $self->{device} = {
        global => {
            status => { status => $map_status->{ $device_status->{data}->{value} } },
            temperature => {
                cpu => (defined($sensors->{data}->{value}->{CpuTemperature}) && $sensors->{data}->{value}->{CpuTemperature} != 0) ?
                    $sensors->{data}->{value}->{CpuTemperature} : undef,
                pcie => (defined($sensors->{data}->{value}->{PcieTemperature}) && $sensors->{data}->{value}->{PcieTemperature} != 0) ?
                    $sensors->{data}->{value}->{PcieTemperature} : undef,
                sio => (defined($sensors->{data}->{value}->{SioTemperature}) && $sensors->{data}->{value}->{SioTemperature} != 0) ?
                    $sensors->{data}->{value}->{SioTemperature} : undef
            },
            fan => {
                cpu => (defined($sensors->{data}->{value}->{CpuFanSpeed}) && $sensors->{data}->{value}->{CpuFanSpeed} != 0) ?
                    $sensors->{data}->{value}->{CpuFanSpeed} : undef
            },
            processes => {}
        }
    };

    foreach (values %{$processes->{data}->{value}}) {
        $self->{device}->{global}->{processes}->{ $_->{Name} } = {
            name => $_->{Name},
            status => $_->{Status} =~ /true|1/i ? 'running' : 'notRunning'
        };
    }
}

1;

__END__

=head1 MODE

Check device.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-device-status>

Set warning threshold (default: '%{status} =~ /warning/').
You can use the following variables: %{status}

=item B<--critical-device-status>

Set critical threshold (default: '%{status} =~ /error/').
You can use the following variables: %{status}

=item B<--warning-process-status>

Set warning threshold.
You can use the following variables: %{name}, %{status}

=item B<--critical-process-status>

Set critical threshold.
You can use the following variables: %{name}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-temperature', 'pcie-temperature', 'sio-temperature',
'cpu-fanspeed'.

=back

=cut
