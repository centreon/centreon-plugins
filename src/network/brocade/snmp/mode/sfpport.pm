#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
use centreon::plugins::statefile;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use Safe;

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s' - %s [instance: %s] - Temp: %.2f C - RX: %.2f mW (%.2f dBm) - TX: %.2f mW (%.2f dBm) - Bias: %s mA",
        $options{instance_value}->{port},
        $options{instance_value}->{interface} ne '' ?
            $options{instance_value}->{interface} :
            $options{instance_value}->{index},
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
        "sfp port '%s' - %s ",
        $options{instance_value}->{port},
        $options{instance_value}->{interface} ne '' ?
            $options{instance_value}->{interface} :
            $options{instance_value}->{index}
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
            type               => COUNTER_TYPE_MULTIPLE,
            cb_prefix_output   => 'prefix_sfp_output',
            cb_long_output     => 'sfp_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All sfp ports are ok',
            group              =>
                [
                    { name => 'status', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                    { name => 'perf', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                    { name => 'temperature', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
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
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'include-instance:s'      => { name => 'include_instance' },
                'exclude-instance:s'      => { name => 'exclude_instance' },
                'include-interface:s'     => { name => 'include_interface' },
                'exclude-interface:s'     => { name => 'exclude_interface' },
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
        oid => $mapping->{sfpTemp}->{oid},
    );

    foreach my $key (keys %$result) {
        next if ($key !~ /^$mapping->{sfpTemp}->{oid}\.(.*)$/);
        my $instance = $1;
        my ($index, $port) = $instance =~ /^(\d+)(?:\.(\d+))?$/;

        $datas->{sfp}->{$instance} = [
            $index,
            $port,
            exists($snmp_names->{$index}) ? $snmp_names->{$index} : ""
        ];
    }

    if (scalar(keys %{$datas->{sfp}}) <= 0) {
        $self->{output}->option_exit(short_msg => "Can't construct cache...");
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
        $self->{output}->option_exit(long_msg => $self->{statefile_cache}->get_string_content());
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $sfp_ports = $self->{statefile_cache}->get(name => 'sfp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($sfp_ports) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $sfp_ports = $self->reload_cache(snmp => $options{snmp});
        $self->{statefile_cache}->read();
    }

    my $results = {};
    foreach (keys %$sfp_ports) {
        next if is_excluded(
            $_,
            $self->{option_results}->{include_instance},
            $self->{option_results}->{exclude_instance}
        );

        next if defined($self->{option_results}->{add_interface_name}) && is_excluded(
            $sfp_ports->{$_}->[2],
            $self->{option_results}->{include_interface},
            $self->{option_results}->{exclude_interface},
        );

        $results->{$_} = $sfp_ports->{$_};
    }

    if (scalar(keys %$results) <= 0) {
        $self->{output}->option_exit(short_msg => "No sfp ports found. Can be: filters, cache file.");
    }

    return $results;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sfp_ports = $self->get_selection(snmp => $options{snmp});

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping)) ],
        instances       => [ keys %$sfp_ports ],
        instance_regexp => '^(.*)$',
        nothing_quit    => 1
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{sfp} = {};

    foreach (sort keys %$sfp_ports) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $_
        );

        if ($result->{sfpTxPowerStatus} eq "notSupported") {
            $self->{output}->output_add(long_msg => "skipping instance '" . $_ . "': status not supported");
            next;
        }

        my $instance = $_;
        my ($index, $port) = $_ =~ /^(\d+)(?:\.(\d+))?$/;
        my $display = defined($self->{option_results}->{add_interface_name}) ?
            exists($sfp_ports->{$_}->[2]) ? $sfp_ports->{$_}->[2] . '-' . $port : $index . '-' . $port
            : $index . '-' . $port;
        $display = $self->get_display_value(value => $display);

        $self->{sfp}->{$instance}->{interface} = defined($self->{option_results}->{add_interface_name})
            && defined($sfp_ports->{$_}->[2]) ?
            $sfp_ports->{$_}->[2] : '';

        $self->{sfp}->{$instance}->{port} = $port;
        $self->{sfp}->{$instance}->{index} = $index;

        $self->{sfp}->{$instance}->{status}->{tx_power_status} = $result->{sfpTxPowerStatus};
        $self->{sfp}->{$instance}->{status}->{rx_power_status} = $result->{sfpRxPowerStatus};
        $self->{sfp}->{$instance}->{status}->{port} = $port;

        $self->{sfp}->{$instance}->{perf}->{tx_output} = $1 if ($result->{sfpTxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output});
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} = $1 if ($result->{sfpTxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{tx_output_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{tx_output_dbm});
        $self->{sfp}->{$instance}->{perf}->{rx_input} = $1 if ($result->{sfpRxPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input});
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} = $1 if ($result->{sfpRxdBmPower} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{rx_input_dbm} /= 1000 if defined($self->{sfp}->{$instance}->{perf}->{rx_input_dbm});
        $self->{sfp}->{$instance}->{perf}->{bias_current} = $1 if ($result->{sfpTxBiasCurrent} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{perf}->{display} = $display;

        $self->{sfp}->{$instance}->{temperature}->{temperature} = $1 if ($result->{sfpTemp} =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$instance}->{temperature}->{display} = $display;
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

=item B<--include-instance>

Filter sfp port by instance (can be a regexp).

=item B<--add-interface-name>

Add the corresponding interface name when set. Used for the instance name in perf data, too.

=item B<--include-interface>

Filter ports by interface name (can be a regexp). Can be used only together with --add-interface-name.

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

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding C<--display-transform-src='eth' --display-transform-dst='ens'>  will replace all occurrences of 'eth' with 'ens'

=back

=cut
