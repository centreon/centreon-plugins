#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::standard::snmp::mode::wan3g;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_connection_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection status: %s',
        $self->{result_values}->{connection_status}
    );
}

sub custom_sim_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'sim status: %s',
        $self->{result_values}->{sim_status}
    );
}

sub custom_modem_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'modem status: %s [imsi: %s][imei: %s][iccid: %s]',
        $self->{result_values}->{modem_status},
        $self->{result_values}->{imsi},
        $self->{result_values}->{imei},
        $self->{result_values}->{iccid}
    );
}

sub custom_radio_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'current band: %s [channel number: %s]',
        $self->{result_values}->{current_band},
        $self->{result_values}->{channel_number}
    );
}

sub custom_network_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'service status: %s',
        $self->{result_values}->{service_status}
    );
}


sub modem_long_output {
    my ($self, %options) = @_;

    return "checking module '" . $options{instance_value}->{display} . "'";
}

sub prefix_modem_output {
    my ($self, %options) = @_;

    return "module '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'modem', type => 3, cb_prefix_output => 'prefix_modem_output', cb_long_output => 'modem_long_output',
          indent_long_output => '    ', message_multiple => 'All cellular modems are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'radio', type => 0, skipped_code => { -10 => 1 } },
                { name => 'network', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
         {
             label => 'modem-status',
             type => 2,
             unknown_default => '%{modem_status} =~ /unknown/i',
             warning_default => '%{modem_status} =~ /lowPowerMode/i',
             critical_default => '%{modem_status} =~ /offLine/i',
             set => {
                key_values => [
                    { name => 'modem_status' }, { name => 'imsi' },
                    { name => 'imei' }, { name => 'iccid' },
                    { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_modem_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'connection-status',
            type => 2,
            unknown_default => '%{connection_status} =~ /unknown/i',
            critical_default => '%{connection_status} =~ /inactive|idle|disconnected|error/i',
            set => {
                key_values => [ { name => 'connection_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_connection_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'sim-status',
            type => 2,
            unknown_default => '%{sim_status} =~ /unknown/i',
            critical_default => '%{sim_status} !~ /ok|unknown/i',
            set => {
                key_values => [ { name => 'sim_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_sim_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature', nlabel => 'modem.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature' }, { name => 'display' } ],
                output_template => 'memory used: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0,
                      unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{radio} = [
        {
            label => 'radio-status',
            type => 2,
            unknown_default => '%{current_band} =~ /unknown/i',
            critical_default => '%{current_band} =~ /invalid|none/i',
            set => {
                key_values => [ { name => 'current_band' }, { name => 'channel_number' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_radio_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'radio-rssi', nlabel => 'modem.radio.rssi.dbm', set => {
                key_values => [ { name => 'rssi' }, { name => 'display' } ],
                output_template => 'received signal strength: %s dBm',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0,
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{network} = [
        {
            label => 'network-status',
            type => 2,
            unknown_default => '%{service_status} =~ /unknown/i',
            critical_default => '%{service_status} =~ /emergencyOnly|noService/i',
            set => {
                key_values => [ { name => 'service_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_network_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'traffic-in', nlabel => 'modem.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'modem.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_current_band = {
    1 => 'unknown', 2 => 'invalid', 3 => 'none',
    4 => 'gsm850', 5 => 'gsm900', 6 => 'gsm1800',
    7 => 'gsm1900', 8 => 'wcdma800', 9 => 'wcdma850',
    10 => 'wcdma1900', 11 => 'wcdma2100', 12 => 'lteBand'
};
my $map_modem_status = {
    1 => 'unknown', 2 => 'offLine', 3 => 'onLine', 4 => 'lowPowerMode'
};
my $map_connection_status = {
    1 => 'unknown', 2 => 'error', 3 => 'connecting',
    4 => 'dormant', 5 => 'connected', 6 => 'disconnected',
    7 => 'idle', 8 => 'active', 9 => 'inactive'
};
my $map_sim_status = {
    1 => 'unknown', 2 => 'ok', 3 => 'notInserted',
    4 => 'removed', 5 => 'initFailure', 6 => 'generalFailure',
    7 => 'locked', 8 => 'chv1Blocked', 9 => 'chv2Blocked',
    10 => 'chv1Rejected', 11 => 'chv2Rejected',
    12 => 'mepLocked', 13 => 'networkRejected'
};
my $map_service_status = {
    1 => 'unknown', 2 => 'noService',
    3 => 'normal', 4 => 'emergencyOnly'
};

my $mapping = {
    rssi               => { oid => '.1.3.6.1.4.1.9.9.661.1.3.4.1.1.1' }, # c3gCurrentGsmRssi
    current_band       => { oid => '.1.3.6.1.4.1.9.9.661.1.3.4.1.1.3', map => $map_current_band }, # c3gGsmCurrentBand
    channel_number     => { oid => '.1.3.6.1.4.1.9.9.661.1.3.4.1.1.4' }, # c3gGsmChannelNumber
    imsi               => { oid => '.1.3.6.1.4.1.9.9.661.1.3.1.1.1' }, # c3gImsi
    imei               => { oid => '.1.3.6.1.4.1.9.9.661.1.3.1.1.2' }, # c3gImei
    iccid              => { oid => '.1.3.6.1.4.1.9.9.661.1.3.1.1.3' }, # c3gIccId
    modem_status       => { oid => '.1.3.6.1.4.1.9.9.661.1.3.1.1.6', map => $map_modem_status }, # c3gModemStatus
    temperature        => { oid => '.1.3.6.1.4.1.9.9.661.1.1.1.12' }, # c3gModemTemperature
    connection_status  => { oid => '.1.3.6.1.4.1.9.9.661.1.1.1.8', map => $map_connection_status }, # c3gConnectionStatus
    sim_status         => { oid => '.1.3.6.1.4.1.9.9.661.1.3.5.1.1.2', map => $map_sim_status }, # c3gGsmSimStatus
    service_status     => { oid => '.1.3.6.1.4.1.9.9.661.1.3.2.1.2', map => $map_service_status }, # c3gGsmCurrentServiceStatus
    traffic_out        => { oid => '.1.3.6.1.4.1.9.9.661.1.3.2.1.19' }, # c3gGsmTotalByteTransmitted
    traffic_in         => { oid => '.1.3.6.1.4.1.9.9.661.1.3.2.1.20' }  # c3gGsmTotalByteReceived
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';
    my $snmp_result = $options{snmp}->get_table(
        oid => $mapping->{connection_status}->{oid},
        nothing_quit => 1
    );

    my $instances = [];
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        push @$instances, $1;
    }

    $options{snmp}->load(
        oids => [ $oid_entPhysicalName ],
        instances => $instances,
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    $self->{modem} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $instance = $1;
        my $name = $snmp_result->{$_};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping module '" . $name . "'.", debug => 1);
            next;
        }

        $self->{modem}->{$instance} = {
            display => $name,
            global => { display => $name },
            radio => { display => $name },
            network => { display => $name }
        };
    }

    return if (scalar(keys %{$self->{modem}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{modem}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{modem}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{modem}->{$_}->{global}->{modem_status} = $result->{modem_status};
        $self->{modem}->{$_}->{global}->{imsi} = $result->{imsi};
        $self->{modem}->{$_}->{global}->{imei} = $result->{imei};
        $self->{modem}->{$_}->{global}->{iccid} = $result->{iccid};
        $self->{modem}->{$_}->{global}->{connection_status} = $result->{connection_status};
        $self->{modem}->{$_}->{global}->{sim_status} = $result->{sim_status};
        $self->{modem}->{$_}->{global}->{temperature} = $result->{temperature};
        $self->{modem}->{$_}->{radio}->{current_band} = $result->{current_band};
        $self->{modem}->{$_}->{radio}->{channel_number} = $result->{channel_number};
        $self->{modem}->{$_}->{radio}->{rssi} = $result->{rssi};
        $self->{modem}->{$_}->{network}->{traffic_in} = $result->{traffic_in};
        $self->{modem}->{$_}->{network}->{traffic_out} = $result->{traffic_out};
        $self->{modem}->{$_}->{network}->{service_status} = $result->{service_status};
    }

    $self->{cache_name} = 'cisco_standard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cellular 3G and 4G LTE WAN.

=over 8

=item B<--filter-name>

Filter by name (can be a regexp).

=item B<--unknown-modem-status>

Set unknown threshold for status (Default: '%{modem_status} =~ /unknown/i').
Can used special variables like: %{modem_status}, %{display}

=item B<--warning-modem-status>

Set warning threshold for status (Default: '%{modem_status} =~ /lowPowerMode/i').
Can used special variables like: %{modem_status}, %{display}

=item B<--critical-modem-status>

Set critical threshold for status (Default: '%{modem_status} =~ /offLine/i').
Can used special variables like: %{modem_status}, %{display}

=item B<--unknown-connection-status>

Set unknown threshold for status (Default: '%{connection_status} =~ /unknown/i').
Can used special variables like: %{connection_status}, %{display}

=item B<--warning-connection-status>

Set warning threshold for status.
Can used special variables like: %{connection_status}, %{display}

=item B<--critical-connection-status>

Set critical threshold for status (Default: '%{connection_status} =~ /inactive|idle|disconnected|error/i').
Can used special variables like: %{connection_status}, %{display}

=item B<--unknown-sim-status>

Set unknown threshold for status (Default: '%{sim_status} =~ /unknown/i').
Can used special variables like: %{sim_status}, %{display}

=item B<--warning-sim-status>

Set warning threshold for status.
Can used special variables like: %{sim_status}, %{display}

=item B<--critical-sim-status>

Set critical threshold for status (Default: '%{sim_status} !~ /ok|unknown/i').
Can used special variables like: %{sim_status}, %{display}

=item B<--unknown-radio-status>

Set unknown threshold for status (Default: '%{current_band} =~ /unknown/i').
Can used special variables like: %{current_band}, %{channel_number}, %{display}

=item B<--warning-radio-status>

Set warning threshold for status.
Can used special variables like: %{current_band}, %{channel_number}, %{display}

=item B<--critical-radio-status>

Set critical threshold for status (Default: '%{current_band} =~ /invalid|none/i').
Can used special variables like: %{current_band}, %{channel_number}, %{display}

=item B<--unknown-network-status>

Set unknown threshold for status (Default: '%{service_status} =~ /unknown/i').
Can used special variables like: %{service_status}, %{display}

=item B<--warning-network-status>

Set warning threshold for status.
Can used special variables like: %{service_status}, %{display}

=item B<--critical-network-status>

Set critical threshold for status (Default: '%{service_status} =~ /emergencyOnly|noService/i').
Can used special variables like: %{service_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature', 'traffic-in', 'traffic-out'.

=back

=cut
