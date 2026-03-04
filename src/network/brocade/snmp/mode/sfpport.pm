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

package network::brocade::snmp::mode::sfpport;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s' - Temp: %.2f C - RX: %.2f mW (%.2f dBm) - TX: %.2f mW (%.2f dBm) - Bias: %s mA",
        $options{instance},
        $options{instance_value}->{temperature}->{temperature},
        $options{instance_value}->{perf}->{rx_input},
        $options{instance_value}->{perf}->{rx_input_dbm},
        $options{instance_value}->{perf}->{tx_output},
        $options{instance_value}->{perf}->{tx_output_dbm},
        $options{instance_value}->{perf}->{bias_current}
    );
}

sub prefix_sfp_output {
    my ($self, %options) = @_;

    return sprintf(
        "sfp port '%s' ",
        $options{instance}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        " RX: %s, TX: %s",
        $self->{result_values}->{tx_power_status},
        $self->{result_values}->{rx_power_status}
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
                ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default =>
                '%{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/',
            warning_default  =>
                '%{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/',
            unknown_default  =>
                '%{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/',
            set              =>
                {
                    key_values                     => [
                        { name => 'port' },
                        { name => 'tx_power_status' },
                        { name => 'rx_power_status' }
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
            output_template => 'input power: %.2f mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'rx-input-power-dbm', display_ok => 0, nlabel => 'port.input.power.dbm', set => {
            key_values      => [ { name => 'rx_input_dbm' } ],
            output_template => 'input power: %.2f dBm',
            perfdatas       => [
                { template => '%.2f', unit => 'dBm', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'tx-output-power', display_ok => 0, nlabel => 'port.output.power.milliwatt', set => {
            key_values      => [ { name => 'tx_output' } ],
            output_template => 'output power: %.2f mW',
            perfdatas       => [
                { template => '%.2f', unit => 'mW', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'tx-output-power-dbm', display_ok => 0, nlabel => 'port.output.power.dbm', set => {
            key_values      => [ { name => 'tx_output_dbm' } ],
            output_template => 'output power: %.2f dBm',
            perfdatas       => [
                { template => '%.2f', unit => 'dBm', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'bias-current', display_ok => 0, nlabel => 'port.bias.current.milliampere', set => {
            key_values      => [ { name => 'bias_current' } ],
            output_template => 'Bias Current : %.2f mA',
            perfdatas       => [
                { template => '%.2f', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
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
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'filter-instance:s'  => { name => 'filter_instance' },
                'add-interface-name' => { name => 'add_interface_name' }
            }
    );

    return $self;
}

my $map_gen_status = {
    1 => 'notSupported',
    2 => 'notApplicable',
    3 => 'highAlarm',
    4 => 'highWarn',
    5 => 'normal',
    6 => 'lowWarn',
    7 => 'lowAlarm'
};

my $mapping = {
    sfpTxPower       =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.5' },# bcsiOptMonLaneTxPowerVal
    sfpTxdBmPower    =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.4' },# bcsiOptMonLaneTxPower
    sfpTxPowerStatus =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.3', map => $map_gen_status },# bcsiOptMonLaneTxPowerStatus
    sfpRxPower       =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.8' },# bcsiOptMonLaneRxPowerVal
    sfpRxdBmPower    =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.7' },# bcsiOptMonLaneRxPower
    sfpRxPowerStatus =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.6', map => $map_gen_status },# bcsiOptMonLaneRxPowerStatus
    sfpTxBiasCurrent =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.9' },# bcsiOptMonLaneTxBiasCurrent
    sfpTemp          =>
        { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.2' },# bcsiOptMonLaneTemperature
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_port = '.1.3.6.1.4.1.1588.3.1.8.1.1.1';# bcsiOptMonLaneEntry
    my $snmp_result = $options{snmp}->get_table(oid => $oid_port, nothing_quit => 1);

    $self->{sfp} = {};
    my $filtered_ports = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{sfpTemp}->{oid}\.(.*)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
            $instance !~ /$self->{option_results}->{filter_instance}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $filtered_ports->{$instance} = {
            instance    => $instance,
            status      => { port => $instance },
            perf        => {},
            temperature => {}
        };
    }

    if (scalar(keys %{$filtered_ports}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No sfp port found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping)) ],
        instances       => [ map($_->{instance}, values(%{$filtered_ports})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$filtered_ports}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $filtered_ports->{$_}->{instance}
        );

        if ($result->{sfpTxPowerStatus} eq "notSupported") {
            $self->{output}->output_add(long_msg => "skipping instance '" . $_ . "': status not supported");
            next;
        }

        my ($index, $port) = $filtered_ports->{$_}->{instance} =~ /^(\d+)(?:\.(\d+))?$/;

        my $interface_name = undef;
        if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
            my $oid = '.1.3.6.1.2.1.31.1.1.1.1' . '.' . $index;
            my $temp_snmp_result = $options{snmp}->get_leef(
                oids          => [ $oid ],
                nothing_quit => 1
            );
            $interface_name = $temp_snmp_result->{$oid};
        }

        my $instance = defined($interface_name) ? $interface_name . '.' . $port : $filtered_ports->{$_}->{instance};

        $self->{sfp}->{$instance} = {
            instance    => $instance,
            status      =>
                {
                    port => $instance
                },
            perf        => {},
            temperature => {}
        };

        $self->{sfp}->{$instance}->{status}->{tx_power_status} = $result->{sfpTxPowerStatus};
        $self->{sfp}->{$instance}->{status}->{rx_power_status} = $result->{sfpRxPowerStatus};

        $self->{sfp}->{$instance}->{perf}->{tx_output} = $1 if ($result->{sfpTxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output});
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} = $1 if ($result->{sfpTxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output_dbm});
        $self->{sfp}->{$instance}->{perf}->{rx_input} = $1 if ($result->{sfpRxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input});
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} = $1 if ($result->{sfpRxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input_dbm});
        $self->{sfp}->{$instance}->{perf}->{bias_current} = $1 if ($result->{sfpTxBiasCurrent} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);

        $self->{sfp}->{$instance}->{temperature}->{temperature} = $1 if ($result->{sfpTemp} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
    }
}

1;

__END__

=head1 MODE

Check SFP port.

=over 8

=item B<--filter-instance>

Filter sfp port by instance (can be a regexp).

=item B<--add-interface-name>

Add the corresponding interface name when set. Used for the instance name in perf data, too.

=item B<--unknown-status>

Define the conditions to match for the status to be WARNING (default: '%{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/').
You can use the following variables: %{tx_power_status}, %{rx_power_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/').
You can use the following variables: %{tx_power_status}, %{rx_power_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/').
You can use the following variables: %{tx_power_status}, %{rx_power_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<rx-input-power (mW)>, C<rx-input-power-dbm (dBm)>, C<tx-output-power (mW)>, C<tx-output-power-dbm (dBm)>, C<bias-current (mA)>, C<temperature (C)>.

=back

=cut
