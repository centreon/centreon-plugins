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

package network::waystream::snmp::mode::sfpport;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s'%s",
        $options{instance},
        $options{instance_value}->{serial} ne '' ? ' [serial: ' . $options{instance_value}->{serial} . ']' : ''
    );
}

sub prefix_sfp_output {
    my ($self, %options) = @_;

    return sprintf(
        "sfp port '%s'%s ",
        $options{instance},
        $options{instance_value}->{serial} ne '' ? ' [serial: ' . $options{instance_value}->{serial} . ']' : ''
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status : %s (Temp: %s, RX: %s, TX: %s, Bias: %s, Volt: %s)",
        $self->{result_values}->{status},
        $self->{result_values}->{temp_status},
        $self->{result_values}->{tx_power_status},
        $self->{result_values}->{rx_power_status},
        $self->{result_values}->{bias_status},
        $self->{result_values}->{volt_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name               => 'sfp',
            type               => 3,
            cb_prefix_output   => 'prefix_sfp_output',
            cb_long_output     => 'sfp_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All sfp ports are ok',
            group              =>
                [
                    { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                    { name => 'perf', type => 0, skipped_code => { -10 => 1 } },
                    { name => 'temperature', type => 0, skipped_code => { -10 => 1 } },
                    { name => 'voltage', type => 0, skipped_code => { -10 => 1 } }
                ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default =>
                '%{status} =~ /invalid/ || %{temp_status} =~ /alarm/ || %{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/ || %{bias_status} =~ /alarm/ || %{volt_status} =~ /alarm/',
            warning_default  =>
                '%{temp_status} =~ /warn/ || %{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/ || %{bias_status} =~ /warn/ || %{volt_status} =~ /warn/',
            unknown_default  =>
                '%{status} =~ /ok/ && (%{temp_status} =~ /unknown/ || %{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/ || %{bias_status} =~ /unknown/ || %{volt_status} =~ /unknown/)',
            set              =>
                {
                    key_values                     => [
                        { name => 'status' },
                        { name => 'serial' },
                        { name => 'port' },
                        { name => 'temp_status' },
                        { name => 'tx_power_status' },
                        { name => 'rx_power_status' },
                        { name => 'bias_status' },
                        { name => 'volt_status' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];

    $self->{maps_counters}->{perf} = [
        { label => 'rx-input-power', display_ok => 0, nlabel => 'port.input.power.milliwatt', set => {
            key_values      => [ { name => 'rx_input' } ],
            output_template => 'input power: %s mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'rx-input-power-dbm', display_ok => 0, nlabel => 'port.input.power.dbm', set => {
            key_values      => [ { name => 'rx_input_dbm' } ],
            output_template => 'input power: %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'tx-output-power', display_ok => 0, nlabel => 'port.output.power.milliwatt', set => {
            key_values      => [ { name => 'tx_output' } ],
            output_template => 'output power: %s mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'tx-output-power-dbm', display_ok => 0, nlabel => 'port.output.power.dbm', set => {
            key_values      => [ { name => 'tx_output_dbm' } ],
            output_template => 'output power: %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'bias-current', display_ok => 0, nlabel => 'port.bias.current.milliampere', set => {
            key_values      => [ { name => 'bias_current' } ],
            output_template => 'Bias Current : %s mA',
            perfdatas       => [
                { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bitrate', display_ok => 0, nlabel => 'port.bitrate.bitspersecond', set => {
            key_values          => [ { name => 'bitrate' } ],
            output_template     => 'Bitrate : %s %s/s',
            output_change_bytes => 2,
            perfdatas           => [
                { template => '%s', unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'temperature', display_ok => 0, nlabel => 'port.temperature.celsius', set => {
            key_values      => [ { name => 'temperature' } ],
            output_template => 'temperature: %.2f C',
            perfdatas       => [
                { template => '%s', unit => 'C', label_extra_instance => 1 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{voltage} = [
        { label => 'volt', display_ok => 0, nlabel => 'port.voltage.volt', set => {
            key_values      => [ { name => 'volt' } ],
            output_template => 'Voltage : %.2f V',
            perfdatas       => [
                { template => '%.2f', unit => 'V', label_extra_instance => 1 },
            ],
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 'filter-port:s' => { name => 'filter_port' } });

    return $self;
}

my $map_status = {
    0 => 'ok', 1 => 'missing', 2 => 'invalid'
};

my $map_gen_status = {
    0 => 'unknown', 1 => 'alarmLow', 2 => 'warnLow',
    3 => 'ok', 4 => 'warnHigh', 5 => 'alarmHigh'
};

my $mapping = {
    sfpSerialNumber        => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.53' },# wsSFPSerialNumber
    sfpStatus              => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.2', map => $map_status },# wsSFPStatus
    sfpBitRate             => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.6' },# wsSFPBitrate
    sfpTxPower             => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.18' },# wsSFPTXPower
    sfpTxdBmPower          => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.22' },# wsSFPTXdBmPower
    sfpTxPowerStatus       => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.17', map => $map_gen_status },# wsSFPTXdBmPowerStatus
    sfpRxPower             => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.20' },# wsSFPRXPower
    sfpRxdBmPower          => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.23' },# wsSFPRXdBmPower
    sfpRxPowerStatus       => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.19', map => $map_gen_status },# wsSFPRXdBmPowerStatus
    sfpTxBiasCurrent       => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.16' },# wsSFPTXCurrent
    sfpTxBiasCurrentStatus => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.15', map => $map_gen_status },# wsSFPTXCurrentStatus
    sfpVolt                => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.14' },# wsSFPVolt
    sfpVoltStatus          => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.13', map => $map_gen_status },# wsSFPVoltStatus
    sfpTemp                => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.12' },# wsSFPTemp
    sfpTempStatus          => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.11', map => $map_gen_status },#  wsSFPTempStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_port = '.1.3.6.1.4.1.9303.4.1.4.1';# wsSFPEntry
    my $snmp_result = $options{snmp}->get_table(oid => $oid_port, nothing_quit => 1);

    $self->{sfp} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{sfpStatus}->{oid}\.(.*)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $instance !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sfp}->{$instance} = {
            instance    => $instance,
            status      => { port => $instance },
            perf        => {},
            temperature => {}
        };
    }

    if (scalar(keys %{$self->{sfp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No sfp port found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping)) ],
        instances       => [ map($_->{instance}, values(%{$self->{sfp}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{sfp}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $self->{sfp}->{$_}->{instance}
        );
        $self->{sfp}->{$_}->{status}->{status} = $result->{sfpStatus};
        $self->{sfp}->{$_}->{status}->{temp_status} = $result->{sfpTempStatus};
        $self->{sfp}->{$_}->{status}->{tx_power_status} = $result->{sfpTxPowerStatus};
        $self->{sfp}->{$_}->{status}->{rx_power_status} = $result->{sfpRxPowerStatus};
        $self->{sfp}->{$_}->{status}->{bias_status} = $result->{sfpTxBiasCurrentStatus};
        $self->{sfp}->{$_}->{status}->{volt_status} = $result->{sfpVoltStatus};
        $self->{sfp}->{$_}->{status}->{serial} = $result->{sfpSerialNumber};

        $self->{sfp}->{$_}->{serial} = $result->{sfpSerialNumber};

        $self->{sfp}->{$_}->{perf}->{tx_output} = $1 if ($result->{sfpTxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{tx_output} /= 1000 if defined($self->{sfp}->{$_}->{perf}->{tx_output});
        $self->{sfp}->{$_}->{perf}->{tx_output_dbm} = $1 if ($result->{sfpTxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{tx_output_dbm} /= 1000 if defined($self->{sfp}->{$_}->{perf}->{tx_output_dbm});
        $self->{sfp}->{$_}->{perf}->{rx_input} = $1 if ($result->{sfpRxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{rx_input} /= 1000 if defined($self->{sfp}->{$_}->{perf}->{rx_input});
        $self->{sfp}->{$_}->{perf}->{rx_input_dbm} = $1 if ($result->{sfpRxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{rx_input_dbm} /= 1000 if defined($self->{sfp}->{$_}->{perf}->{rx_input_dbm});
        $self->{sfp}->{$_}->{perf}->{bias_current} = $1 if ($result->{sfpTxBiasCurrent} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{bitrate} = $1 if ($result->{sfpBitRate} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{perf}->{bitrate} *= 1000000 if defined($self->{sfp}->{$_}->{perf}->{bitrate});;#Mbps

        $self->{sfp}->{$_}->{temperature}->{temperature} = $1 if ($result->{sfpTemp} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{voltage}->{volt} = $1 if ($result->{sfpVolt} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{voltage}->{volt} /= 1000 if defined($self->{sfp}->{$_}->{voltage}->{volt});
    }
}

1;

__END__

=head1 MODE

Check SFP port.

=over 8

=item B<--filter-port>

Filter ports by index (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /ok/ && (%{temp_status} =~ /unknown/ || %{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/ || %{bias_status} =~ /unknown/ || %{volt_status} =~ /unknown/)').
You can use the following variables: %{status}, %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}, %{volt_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{temp_status} =~ /warn/ || %{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/ || %{bias_status} =~ /warn/ || %{volt_status} =~ /warn/').
You can use the following variables: %{status}, %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}, %{volt_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /invalid/ || %{temp_status} =~ /alarm/ || %{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/ || %{bias_status} =~ /alarm/ || %{volt_status} =~ /alarm/').
You can use the following variables: %{status}, %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}, %{volt_status}
=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<rx-input-power (mW)>, C<rx-input-power-dbm (dBm)>, C<tx-output-power (mW)>, C<tx-output-power-dbm (dBm)>, C<bias-current (mA)>, C<temperature (C)>, C<voltage (V)>, C<bitrate (b/s)>.

=back

=cut
