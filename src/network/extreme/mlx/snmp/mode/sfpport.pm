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

package network::extreme::mlx::snmp::mode::sfpport;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s' - Temp: %.2f C - RX: %.2f dBm - TX: %.2f dBm - Bias: %s mA ",
        $options{instance},
        $options{instance_value}->{temperature}->{temperature},
        $options{instance_value}->{perf}->{rx_input_dbm},
        $options{instance_value}->{perf}->{tx_output_dbm},
        $options{instance_value}->{perf}->{bias_current},
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
        "Temp: %s, RX: %s, TX: %s, Bias: %s",
        $self->{result_values}->{temp_status},
        $self->{result_values}->{rx_power_status},
        $self->{result_values}->{tx_power_status},
        $self->{result_values}->{bias_status},
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
                '%{temp_status} =~ /alarm/ || %{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/ || %{bias_status} =~ /alarm/',
            warning_default  =>
                '%{temp_status} =~ /warn/ || %{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/ || %{bias_status} =~ /warn/',
            unknown_default  =>
                '%{temp_status} =~ /unknown/ || %{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/ || %{bias_status} =~ /unknown/',
            set              =>
                {
                    key_values                     => [
                        { name => 'port' },
                        { name => 'temp_status' },
                        { name => 'tx_power_status' },
                        { name => 'rx_power_status' },
                        { name => 'bias_status' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];

    $self->{maps_counters}->{perf} = [
        { label => 'rx-input-power-dbm', display_ok => 0, nlabel => 'port.input.power.dbm', set => {
            key_values      => [ { name => 'rx_input_dbm' } ],
            output_template => 'input power: %.2f dBm',
            perfdatas       => [
                { template => '%.2f', unit => 'dBm', label_extra_instance => 1 }
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

    $options{options}->add_options(arguments => { 'filter-port:s' => { name => 'filter_port' } });

    return $self;
}

my $mapping = {
    sfpTxdBmPower    => { oid => '.1.3.6.1.4.1.1991.1.1.3.3.6.1.2' },# snIfOpticalMonitoringTxPower
    sfpRxdBmPower    => { oid => '.1.3.6.1.4.1.1991.1.1.3.3.6.1.3' },# snIfOpticalMonitoringRxPower
    sfpTxBiasCurrent => { oid => '.1.3.6.1.4.1.1991.1.1.3.3.6.1.4' },# snIfOpticalMonitoringTxBiasCurrent
    sfpTemp          => { oid => '.1.3.6.1.4.1.1991.1.1.3.3.6.1.1' },# snIfOpticalMonitoringTemperature
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_port = '.1.3.6.1.4.1.1991.1.1.3.3.6.1';# snIfOpticalMonitoringInfoEntry
    my $snmp_result = $options{snmp}->get_table(oid => $oid_port, nothing_quit => 1);

    $self->{sfp} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{sfpTemp}->{oid}\.(.*)$/);
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

        my ($value, $unit, @status) = split /\s+/, $self->normalize_oid_value(value => $result->{sfpTemp});
        $self->{sfp}->{$_}->{status}->{temp_status} = join ' ', @status;
        $self->{sfp}->{$_}->{temperature}->{temperature} = $1 if ($value =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);

        ($value, $unit, @status) = split /\s+/, $self->normalize_oid_value(value => $result->{sfpRxdBmPower});
        $self->{sfp}->{$_}->{perf}->{rx_input_dbm} = $1 if ($value =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{status}->{rx_power_status} = join ' ', @status;;

        ($value, $unit, @status) = split /\s+/, $self->normalize_oid_value(value => $result->{sfpTxdBmPower});
        $self->{sfp}->{$_}->{perf}->{tx_output_dbm} = $1 if ($value =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{status}->{tx_power_status} = join ' ', @status;;

        ($value, $unit, @status) = split /\s+/, $self->normalize_oid_value(value => $result->{sfpTxBiasCurrent});
        $self->{sfp}->{$_}->{perf}->{bias_current} = $1 if ($value =~ /([-+]?[0-9]+(?:\.[0-9]+)?)/);
        $self->{sfp}->{$_}->{status}->{bias_status} = join ' ', @status;;
    }
}

sub normalize_oid_value {
    my ($self, %options) = @_;

    # Remove optional trailing colon from unit (e.g. "C:")
    $options{value} =~ s/://;
    $options{value} =~ s/^\s+//;# remove leading spaces
    $options{value} =~ s/\s+$//;# remove trailing spaces

    return $options{value}
}

1;

__END__

=head1 MODE

Check SFP port.

=over 8

=item B<--filter-port>

Filter ports by index (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be WARNING (default: '%{temp_status} =~ /unknown/ || %{tx_power_status} =~ /unknown/ || %{rx_power_status} =~ /unknown/ || %{bias_status} =~ /unknown/').
You can use the following variables: %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{temp_status} =~ /warn/ || %{tx_power_status} =~ /warn/ || %{rx_power_status} =~ /warn/ || %{bias_status} =~ /warn/').
You can use the following variables: %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL '%{temp_status} =~ /alarm/ || %{tx_power_status} =~ /alarm/ || %{rx_power_status} =~ /alarm/ || %{bias_status} =~ /alarm/').
You can use the following variables: %{temp_status}, %{tx_power_status}, %{rx_power_status}, %{bias_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<rx-input-power-dbm (dBm)>,  C<tx-output-power-dbm (dBm)>, C<bias-current (mA)>, C<temperature (C)>.

=back

=cut