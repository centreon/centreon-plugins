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
use centreon::plugins::statefile;
use Safe;

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s'%s - Temp: %.2f C - RX: %.2f mW (%.2f dBm) - TX: %.2f mW (%.2f dBm) - Bias: %s mA - Volt: %.2f V",
        $options{instance},
        $options{instance_value}->{serial} ne '' ? ' [serial: ' . $options{instance_value}->{serial} . ']' : '',
        $options{instance_value}->{temperature}->{temperature},
        $options{instance_value}->{perf}->{rx_input},
        $options{instance_value}->{perf}->{rx_input_dbm},
        $options{instance_value}->{perf}->{tx_output},
        $options{instance_value}->{perf}->{tx_output_dbm},
        $options{instance_value}->{perf}->{bias_current},
        $options{instance_value}->{voltage}->{volt},
    );
}

sub prefix_sfp_output {
    my ($self, %options) = @_;

    return sprintf(
        "sfp port '%s'%s%s ",
        $options{instance},
        $options{instance_value}->{interface} ne '' ? ' - ' . $options{instance_value}->{interface} : '',
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
            key_values      => [ { name => 'rx_input' }, { name => 'display' } ],
            output_template => 'input power: %.2f mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'rx-input-power-dbm', display_ok => 0, nlabel => 'port.input.power.dbm', set => {
            key_values      => [ { name => 'rx_input_dbm' }, { name => 'display' } ],
            output_template => 'input power: %.2f dBm',
            perfdatas       => [
                { template => '%.2f', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'tx-output-power', display_ok => 0, nlabel => 'port.output.power.milliwatt', set => {
            key_values      => [ { name => 'tx_output' }, { name => 'display' } ],
            output_template => 'output power: %.2f mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'tx-output-power-dbm', display_ok => 0, nlabel => 'port.output.power.dbm', set => {
            key_values      => [ { name => 'tx_output_dbm' }, { name => 'display' } ],
            output_template => 'output power: %.2f dBm',
            perfdatas       => [
                { template => '%.2f', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bias-current', display_ok => 0, nlabel => 'port.bias.current.milliampere', set => {
            key_values      => [ { name => 'bias_current' }, { name => 'display' } ],
            output_template => 'Bias Current : %.2f mA',
            perfdatas       => [
                { template => '%.2f', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bitrate', display_ok => 0, nlabel => 'port.bitrate.bitspersecond', set => {
            key_values          => [ { name => 'bitrate' }, { name => 'display' } ],
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
            key_values      => [ { name => 'temperature' }, { name => 'display' } ],
            output_template => 'temperature: %.2f C',
            perfdatas       => [
                { template => '%s', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        }
    ];

    $self->{maps_counters}->{voltage} = [
        { label => 'volt', display_ok => 0, nlabel => 'port.voltage.volt', set => {
            key_values      => [ { name => 'volt' }, { name => 'display' } ],
            output_template => 'Voltage : %.2f V',
            perfdatas       => [
                { template => '%.2f', unit => 'V', label_extra_instance => 1, instance_use => 'display' },
            ],
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-port:s'           => { name => 'filter_port' },
            'filter-serial:s'         => { name => 'filter_serial' },
            'filter-interface:s'      => { name => 'filter_interface' },
            'add-interface-name'      => { name => 'add_interface_name' },
            'reload-cache-time:s'     => { name => 'reload_cache_time', default => 180 },
            'show-cache'              => { name => 'show_cache' },
            'display-transform-src:s' => { name => 'display_transform_src' },
            'display-transform-dst:s' => { name => 'display_transform_dst' }
        }
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    $self->{safe} = Safe->new();
    $self->{safe}->share('$assign_var');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{statefile_cache}->check_options(%options);
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

sub reload_cache {
    my ($self, %options) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{sfp} = {};
    my $snmp_names = {};

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        my $oid_interface_name = '.1.3.6.1.2.1.31.1.1.1.1';
        my $result = $options{snmp}->get_table(
            oid => $oid_interface_name,
        );

        foreach my $key (keys %$result) {
            next if $key !~ /^$oid_interface_name\.(.*)$/;
            my $instance = $1;

            $snmp_names->{$instance} = $self->{output}->decode($result->{$key});
        }
    }

    my $result = $options{snmp}->get_table(
        oid   => $mapping->{sfpSerialNumber}->{oid},
    );

    foreach my $key (keys %$result) {
        next if ($key !~ /$mapping->{sfpSerialNumber}->{oid}\.([0-9]+)$/);
        my $instance = $1;

        $datas->{sfp}->{$instance} = [
            $self->{output}->decode($result->{$mapping->{sfpSerialNumber}->{oid} . '.' . $instance}),
            exists($snmp_names->{$instance}) ? $snmp_names->{$instance} : ""
        ];
    }

    if (scalar(keys %{$datas->{sfp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
    return $datas->{sfp};
}

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile =>
        'cache_snmpstandard_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $sfp_ports = $self->{statefile_cache}->get(name => 'sfp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($sfp_ports) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $sfp_ports = $self->reload_cache(snmp => $options{snmp});
        $self->{statefile_cache}->read();
    }

    my $results = {};
    foreach (keys %$sfp_ports) {
        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $_ !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_ . "': no matching filter.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $sfp_ports->{$_}->[0] !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $sfp_ports->{$_}->[0] . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{add_interface_name}) &&
            defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
            $sfp_ports->{$_}->[1] !~ /$self->{option_results}->{filter_interface}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $sfp_ports->{$_}->[1] . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        $results->{$_} = $sfp_ports->{$_};
    }

    if (scalar(keys %$results) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sfp ports found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }

    return $results;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sfp_ports = $self->get_selection(snmp => $options{snmp});

    $options{snmp}->load(
        oids         => [ map($_->{oid}, values(%$mapping)) ],
        instances    => [ keys %$sfp_ports ],
        nothing_quit => 1
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{sfp} = {};

    foreach (keys %$sfp_ports) {
        my $instance = $_;

        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $instance
        );

        my $display = defined($self->{option_results}->{add_interface_name}) ?
            $instance . '-' . exists($sfp_ports->{$instance}->[1]) ? $sfp_ports->{$instance}->[1] : '' : $instance;
        $display = $self->get_display_value(value => $display);

        $self->{sfp}->{$instance}->{interface} = defined($self->{option_results}->{add_interface_name}) &&
            exists($sfp_ports->{$instance}->[1]) ?
            $sfp_ports->{$instance}->[1] :
            '';

        $self->{sfp}->{$instance}->{status}->{port} = $instance;
        $self->{sfp}->{$instance}->{status}->{status} = $result->{sfpStatus};
        $self->{sfp}->{$instance}->{status}->{temp_status} = $result->{sfpTempStatus};
        $self->{sfp}->{$instance}->{status}->{tx_power_status} = $result->{sfpTxPowerStatus};
        $self->{sfp}->{$instance}->{status}->{rx_power_status} = $result->{sfpRxPowerStatus};
        $self->{sfp}->{$instance}->{status}->{bias_status} = $result->{sfpTxBiasCurrentStatus};
        $self->{sfp}->{$instance}->{status}->{volt_status} = $result->{sfpVoltStatus};
        $self->{sfp}->{$instance}->{status}->{serial} = $result->{sfpSerialNumber};

        $self->{sfp}->{$instance}->{serial} = $result->{sfpSerialNumber};

        $self->{sfp}->{$instance}->{perf}->{tx_output} = $1 if ($result->{sfpTxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output});
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} = $1 if ($result->{sfpTxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output_dbm});
        $self->{sfp}->{$instance}->{perf}->{rx_input} = $1 if ($result->{sfpRxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input});
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} = $1 if ($result->{sfpRxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input_dbm});
        $self->{sfp}->{$instance}->{perf}->{bias_current} = $1 if ($result->{sfpTxBiasCurrent} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{bitrate} = $1 if ($result->{sfpBitRate} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{bitrate} *= 1000000 if defined($self->{sfp}->{$instance}->{perf}->{bitrate});#Mbps
        $self->{sfp}->{$instance}->{perf}->{display} = $display;

        $self->{sfp}->{$instance}->{temperature}->{temperature} = $1 if ($result->{sfpTemp} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{temperature}->{display} = $display;

        $self->{sfp}->{$instance}->{voltage}->{volt} = $1 if ($result->{sfpVolt} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{voltage}->{volt} /= 1000 if defined($self->{sfp}->{$instance}->{voltage}->{volt});
        $self->{sfp}->{$instance}->{voltage}->{display} = $display;
    }
}

sub get_display_value {
    my ($self, %options) = @_;

    our $assign_var = $options{value};
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));

        $self->{safe}->reval("\$assign_var =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}",
            1);
        if ($@) {
            die 'Unsafe code evaluation: ' . $@;
        }
    }

    return $assign_var;
}

1;

__END__

=head1 MODE

Check SFP port.

=over 8

=item B<--filter-port>

Filter ports by index (can be a regexp).

=item B<--filter-serial>

Filter ports by serial (can be a regexp).

=item B<--filter-interface>

Filter ports by interface name (can be a regexp). Can be used only together with --add-interface-name.

=item B<--add-interface-name>

Add the corresponding interface name when set. Used for the instance name in perf data, too.

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

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding C<--display-transform-src='eth' --display-transform-dst='ens'>  will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface data.

=back

=cut
