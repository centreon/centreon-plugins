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

package hardware::devices::camera::optelecom::snmp::mode::alarms;

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

sub custom_alarm_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'alarm.enabled.count',
        instances => [$self->{result_values}->{deviceName}, $self->{result_values}->{alarmName}],
        value => sprintf('%s', $self->{result_values}->{alarmValue})
    );
}

sub prefix_alarm_output {
    my ($self, %options) = @_;

    return "alarm '" . $options{instance_value}->{alarmName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output',
          indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'alarms', type => 1, cb_prefix_output => 'prefix_alarm_output', message_multiple => 'all alarms are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{alarms} = [
        {
            label => 'alarm-status',
            type => 2,
            critical_default => '%{alarm} eq "enabled"',
            set => {
                key_values => [
                    { name => 'alarm' }, { name => 'alarmValue' }, { name => 'alarmName' }, { name => 'deviceName' }
                ],
                closure_custom_output => $self->can('custom_alarm_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata => $self->can('custom_alarm_perfdata')
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
my $mapping_stream = {
    streamDesc      => { oid => '.1.3.6.1.4.1.17534.2.2.2.2.1.5' }, # optcStreamDescription
    streamDownAlarm => { oid => '.1.3.6.1.4.1.17534.2.2.2.2.1.10' } # optcStreamDownAlarm
};
my $mapping_input = {
    inputDesc       => { oid => '.1.3.6.1.4.1.17534.2.2.2.3.1.4' }, # optcInputDescription
    signalLostAlarm => { oid => '.1.3.6.1.4.1.17534.2.2.2.3.1.7' }, # optcSignalLostAlarm
    formatAlarm     => { oid => '.1.3.6.1.4.1.17534.2.2.2.3.1.8' }  # optcFormatAlarm
};
my $mapping_image_quality = {
    badContrastAlarm => { oid => '.1.3.6.1.4.1.17534.2.2.3.1.1.5' }, # optcBadContrastAlarm
    badExposureAlarm => { oid => '.1.3.6.1.4.1.17534.2.2.3.1.1.6' }, # optcBadExposureAlarm
    lowDetailAlarm   => { oid => '.1.3.6.1.4.1.17534.2.2.3.1.1.7' }, # optcLowDetailAlarm
    lowSnrAlarm      => { oid => '.1.3.6.1.4.1.17534.2.2.3.1.1.8' }  # optcLowSnrAlarm
};
my $mapping_tampering = {
    noMatchAlarm         => { oid => '.1.3.6.1.4.1.17534.2.2.3.2.1.3' }, # optcNoMatchAlarm
    positionChangedAlarm => { oid => '.1.3.6.1.4.1.17534.2.2.3.2.1.4' }  # optcPositionChangedAlarm
};

sub add_stream_alarm {
    my ($self, %options) = @_;

    my $oid_streamTable = '.1.3.6.1.4.1.17534.2.2.2.2.1'; # optcStreamEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_streamTable,
        start => $mapping_stream->{streamDesc}->{oid}
    );

    foreach (keys %$snmp_result) {
        next if (! /\.(\d+)\.(\d+)$/);
        my ($deviceIndex, $streamIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_stream, results => $snmp_result, instance => $deviceIndex . '.' . $streamIndex);

        my $name = 'streamDown ' . $result->{streamDesc};

        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{streamDownAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{streamDownAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

sub add_input_alarm {
    my ($self, %options) = @_;

    my $oid_inputTable = '.1.3.6.1.4.1.17534.2.2.2.3.1'; # optcInputEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_inputTable,
        start => $mapping_stream->{inputDesc}->{oid}
    );

    $self->{inputs} = {};
    foreach (keys %$snmp_result) {
        next if (! /\.(\d+)\.(\d+)$/);
        my ($deviceIndex, $inputIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_input, results => $snmp_result, instance => $deviceIndex . '.' . $inputIndex);

        $self->{inputs}->{$deviceIndex . $inputIndex} = $result->{inputDesc};

        my $name = 'signalLost ' . $result->{inputDesc};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{signalLostAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{signalLostAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };

        $name = 'format ' . $result->{inputDesc};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{formatAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{formatAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

sub add_image_quality_alarm {
    my ($self, %options) = @_;

    my $oid_imageQualityTable = '.1.3.6.1.4.1.17534.2.2.3.1.1'; # optcImageQualityEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_imageQualityTable,
        start => $mapping_image_quality->{badContrastAlarm}->{oid}
    );

    foreach (keys %$snmp_result) {
        next if (! /\.(\d+)\.(\d+)$/);
        my ($deviceIndex, $inputIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_image_quality, results => $snmp_result, instance => $deviceIndex . '.' . $inputIndex);

        my $name = 'badContrast ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{badContrastAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{badContrastAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };

        $name = 'badExposure ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{badExposureAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{badExposureAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };

        $name = 'lowDetail ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{lowDetailAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{lowDetailAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };

        $name = 'lowSnr ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{lowSnrAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{lowSnrAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

sub add_tampering_alarm {
    my ($self, %options) = @_;

    my $oid_tamperingTable = '.1.3.6.1.4.1.17534.2.2.3.2.1'; # optcTamperingEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tamperingTable,
        start => $mapping_tampering->{noMatchAlarm}->{oid}
    );

    foreach (keys %$snmp_result) {
        next if (! /\.(\d+)\.(\d+)$/);
        my ($deviceIndex, $inputIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_tampering, results => $snmp_result, instance => $deviceIndex . '.' . $inputIndex);

        my $name = 'noMatchoptcNoMatchAlarm ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{noMatchAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{noMatchAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };

        $name = 'positionChanged ' . $self->{inputs}->{$deviceIndex . $inputIndex};
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $result->{positionChangedAlarm} =~ /1|true/i ? 1 : 0,
            alarm => $result->{positionChangedAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

sub add_network_alarm {
    my ($self, %options) = @_;

    my $oid_networkOverloadAlarm = '.1.3.6.1.4.1.17534.2.2.2.4.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_networkOverloadAlarm
    );

    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $deviceIndex = $1;

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $name = 'networkOverload';
        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $snmp_result->{$_} =~ /1|true/i ? 1 : 0,
            alarm => $snmp_result->{$_} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }
}

sub add_psu_alarm {
    my ($self, %options) = @_;

    # it's not linked to a device... weird..
    my $oid_powerSupplyAlarm = '.1.3.6.1.4.1.17534.2.2.1.3.3.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_powerSupplyAlarm]
    );

    if (defined($snmp_result->{$oid_powerSupplyAlarm})) {
        foreach (keys %{$self->{devices}}) {
            my $name = 'powersupply';
            $self->{devices}->{$_}->{alarms}->{$name} = {
                deviceName => $self->{devices}->{$_}->{deviceName},
                alarmName => $name,
                alarmValue => $snmp_result->{$oid_powerSupplyAlarm} =~ /1|true/i ? 1 : 0,
                alarm => $snmp_result->{$oid_powerSupplyAlarm} =~ /1|true/i ? 'enabled' : 'disabled'
            };
        }
    }
}

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

        $self->{devices}->{$instance} = { deviceName => $name, alarms => {} };
    }

    my $oid_temperatureAlarm = '.1.3.6.1.4.1.17534.2.2.1.3.1.1.5'; # optcTemperatureAlarm
    $snmp_result = $options{snmp}->get_table(oid => $oid_temperatureAlarm);
    foreach (keys %$snmp_result) {
        next if (! /\.(\d+).(\d+)$/);
        my ($deviceIndex, $probeIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $name = 'temperature ' . $probeIndex;

        $self->{devices}->{$deviceIndex}->{alarms}->{$name} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            alarmName => $name,
            alarmValue => $snmp_result->{$_} =~ /1|true/i ? 1 : 0,
            alarm => $snmp_result->{$_} =~ /1|true/i ? 'enabled' : 'disabled'
        };
    }

    $self->add_stream_alarm(snmp => $options{snmp});
    $self->add_input_alarm(snmp => $options{snmp});
    $self->add_image_quality_alarm(snmp => $options{snmp});
    $self->add_tampering_alarm(snmp => $options{snmp});
    $self->add_network_alarm(snmp => $options{snmp});
    $self->add_psu_alarm(snmp => $options{snmp});
}

1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-device-name>

Filter devices by name (can be a regexp).

=item B<--unknown-alarm-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{alarm}, %{alarmName}, %{deviceName}

=item B<--warning-alarm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables:  %{alarm}, %{alarmName}, %{deviceName}

=item B<--critical-alarm-status>

Define the conditions to match for the status to be CRITICAL (default: '%{alarm} eq "enabled"').
You can use the following variables:  %{alarm}, %{alarmName}, %{deviceName}

=back

=cut
