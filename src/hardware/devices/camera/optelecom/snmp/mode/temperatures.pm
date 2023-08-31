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

package hardware::devices::camera::optelecom::snmp::mode::temperatures;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_alarm_output {
    my ($self, %options) = @_;

    return sprintf(
        "alarm: %s",
        $self->{result_values}->{alarm}
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking device '%s'",
        $options{instance_value}->{deviceName}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{deviceName}
    );
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return "temperature probe '" . $options{instance_value}->{probeIndex} . "' ";
}   

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output',
          indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'temperatures', type => 1, cb_prefix_output => 'prefix_temperature_output', message_multiple => 'all temperatures are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{temperatures} = [
        { label => 'probe-temperature', nlabel => 'probe.temperature.celsius', set => {
                key_values => [ { name => 'actual' }, { name => 'probeIndex' }, { name => 'deviceName' } ],
                output_template => 'temperature: %.2f C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => [$self->{result_values}->{deviceName}, $self->{result_values}->{probeIndex}],
                        value => sprintf('%.2f', $self->{result_values}->{actual}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        },
        {
            label => 'alarm-status',
            type => 2,
            critical_default => '%{alarm} eq "enabled"',
            set => {
                key_values => [
                    { name => 'alarm' }, { name => 'alarmValue' }, { name => 'probeIndex' }, { name => 'deviceName' }
                ],
                closure_custom_output => $self->can('custom_alarm_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => 'probe.temperature.alarm.enabled.count',
                        instances => [$self->{result_values}->{deviceName}, $self->{result_values}->{probeIndex}],
                        value => sprintf('%s', $self->{result_values}->{alarmValue})
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-device-name:s' => { name => 'filter_device_name' }
    });

    return $self;
}

my $mapping_device = {
    serial     => { oid => '.1.3.6.1.4.1.17534.2.2.1.1.1.6' }, # optcSerialNumber
    userLabel1 => { oid => '.1.3.6.1.4.1.17534.2.2.1.1.1.8' }, # optcUserLabel1
    userLabel2 => { oid => '.1.3.6.1.4.1.17534.2.2.1.1.1.9' }  # optcUserLabel2
};

my $mapping_temperature = {
    actual => { oid => '.1.3.6.1.4.1.17534.2.2.1.3.1.1.2' }, # optcActualTemperature
    alarm  => { oid => '.1.3.6.1.4.1.17534.2.2.1.3.1.1.5' }, # optcTemperatureAlarm
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_deviceTable = '.1.3.6.1.4.1.17534.2.2.1.1.1'; # optcSysInfoEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_deviceTable,
        start => $mapping_device->{serial}->{oid},
        end => $mapping_device->{userLabel2}->{oid},
        nothing_quit => 1
    );

    $self->{devices} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_device->{serial}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_device, results => $snmp_result, instance => $instance);

        my $name = defined($result->{userLabel1}) && $result->{userLabel1} ne '' ? $result->{userLabel1} : $result->{serial};
        next if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_device_name}/);

        $self->{devices}->{$instance} = { deviceName => $name, temperatures => {} };
    }

    my $oid_temperatureTable = '.1.3.6.1.4.1.17534.2.2.1.3.1.1'; # optcTemperatureEntry
    $snmp_result = $options{snmp}->get_table(oid => $oid_temperatureTable);
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_temperature->{actual}->{oid}\.(\d+).(\d+)$/);
        my ($deviceIndex, $probeIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_temperature, results => $snmp_result, instance => $deviceIndex . '.' . $probeIndex);

        $self->{devices}->{$deviceIndex}->{temperatures}->{$probeIndex} = {
            probeIndex => $probeIndex,
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            actual => $result->{actual},
            alarmValue => $result->{alarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{alarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

1;

__END__

=head1 MODE

Check temperatures.

=over 8

=item B<--filter-device-name>

Filter devices by name (can be a regexp).

=item B<--unknown-alarm-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{alarm}, %{probeIndex}, %{deviceName}

=item B<--warning-alarm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables:  %{alarm}, %{probeIndex}, %{deviceName}

=item B<--critical-alarm-status>

Define the conditions to match for the status to be CRITICAL (default: '%{alarm} eq "enabled"').
You can use the following variables:  %{alarm}, %{probeIndex}, %{deviceName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'probe-temperature'.

=back

=cut
