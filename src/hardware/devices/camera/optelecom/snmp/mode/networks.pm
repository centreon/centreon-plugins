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

package hardware::devices::camera::optelecom::snmp::mode::networks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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

sub prefix_network_output {
    my ($self, %options) = @_;

    return sprintf(
        "network '%s' ",
        $options{instance_value}->{ipAddress}
    );
}   

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output',
          indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'networks', type => 1, cb_prefix_output => 'prefix_network_output', message_multiple => 'all networks are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{networks} = [
        { label => 'traffic-in', nlabel => 'network.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'trafficIn' }, { name => 'deviceName' }, { name => 'ipAddress' } ],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{deviceName}, $self->{result_values}->{ipAddress}],
                        value => $self->{result_values}->{trafficIn},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'traffic-out', nlabel => 'network.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'trafficOut' }, { name => 'deviceName' }, { name => 'ipAddress' } ],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{deviceName}, $self->{result_values}->{ipAddress}],
                        value => $self->{result_values}->{trafficOut},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
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

my $mapping_network = {
    ipAddress  => { oid => '.1.3.6.1.4.1.17534.2.2.1.4.1.4' }, # optcIPAddress
    trafficOut => { oid => '.1.3.6.1.4.1.17534.2.2.1.5.1.1' }, # optcTotalTxBitrate
    trafficIn  => { oid => '.1.3.6.1.4.1.17534.2.2.1.5.1.2' }  # optcTotalRxBitrate
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

        $self->{devices}->{$instance} = { deviceName => $name, networks => {} };
    }

    my $oid_networkTable = '.1.3.6.1.4.1.17534.2.2.1.4.1'; # optcNetworkSettingsEntry
    my $oid_networkStatsTable = '.1.3.6.1.4.1.17534.2.2.1.5.1'; # optcNetworkStatisticsEntry
    $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ { oid => $oid_networkTable }, { oid => $oid_networkStatsTable } ],
        return_type => 1
    );
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_network->{ipAddress}->{oid}\.(\d+).(\d+)$/);
        my ($deviceIndex, $netIndex) = ($1, $2);

        next if (!defined($self->{devices}->{$deviceIndex}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_network, results => $snmp_result, instance => $deviceIndex . '.' . $netIndex);

        $self->{devices}->{$deviceIndex}->{networks}->{$netIndex} = {
            deviceName => $self->{devices}->{$deviceIndex}->{deviceName},
            ipAddress => $result->{ipAddress},
            trafficIn => $result->{trafficIn} * 1000,
            trafficOut => $result->{trafficOut} * 1000
        };
    }
}

1;

__END__

=head1 MODE

Check networks traffic.

=over 8

=item B<--filter-device-name>

Filter devices by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
