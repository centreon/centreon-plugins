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

package network::waystream::snmp::mode::cpudetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_cpu_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}));
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    if (!defined($self->{instance_mode}->{total_cpu})) {
        $self->{instance_mode}->{total_cpu} = 0;
        foreach (keys %{$options{new_datas}}) {
            if (/$self->{instance}_/) {
                my $new_total = $options{new_datas}->{$_};
                next if (!defined($options{old_datas}->{$_}));
                my $old_total = $options{old_datas}->{$_};

                my $diff_total = $new_total - $old_total;
                if ($diff_total < 0) {
                    $self->{instance_mode}->{total_cpu} += $old_total;
                } else {
                    $self->{instance_mode}->{total_cpu} += $diff_total;
                }
            }
        }
    }

    if ($self->{instance_mode}->{total_cpu} <= 0) {
        $self->{error_msg} = "counter not moved";
        return -12;
    }

    if ($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} > $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) {
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} = 0;
    }
    $self->{result_values}->{prct_used} =
        ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} -
            $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) / 10 * 100 /
            $self->{instance_mode}->{total_cpu};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'user', nlabel => 'cpu.user.utilization.percentage', set => {
            key_values                        => [],
            closure_custom_calc               => $self->can('custom_cpu_calc'),
            closure_custom_calc_extra_options => { label_ref => 'wsCPUUserLoad' },
            manual_keys                       => 1,
            threshold_use                     => 'prct_used',
            output_use                        => 'prct_used',
            output_template                   => 'User %.2f %%',
            perfdatas                         =>
                [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'nice', nlabel => 'cpu.nice.utilization.percentage', set => {
            key_values                        => [],
            closure_custom_calc               => $self->can('custom_cpu_calc'),
            closure_custom_calc_extra_options => { label_ref => 'wsCPUNiceLoad' },
            manual_keys                       => 1,
            threshold_use                     => 'prct_used',
            output_use                        => 'prct_used',
            output_template                   => 'Nice %.2f %%',
            perfdatas                         =>
                [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'system', nlabel => 'cpu.system.utilization.percentage', set => {
            key_values                        => [],
            closure_custom_calc               => $self->can('custom_cpu_calc'),
            closure_custom_calc_extra_options => { label_ref => 'wsCPUSystemLoad' },
            manual_keys                       => 1,
            threshold_use                     => 'prct_used',
            output_use                        => 'prct_used',
            output_template                   => 'System %.2f %%',
            perfdatas                         =>
                [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'idle', nlabel => 'cpu.idle.utilization.percentage', set => {
            key_values                        => [],
            closure_custom_calc               => $self->can('custom_cpu_calc'),
            closure_custom_calc_extra_options => { label_ref => 'wsCPUIdleLoad' },
            manual_keys                       => 1,
            threshold_use                     => 'prct_used',
            output_use                        => 'prct_used',
            output_template                   => 'Idle %.2f %%',
            perfdatas                         =>
                [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'interrupt', nlabel => 'cpu.interrupt.utilization.percentage', set => {
            key_values                        => [],
            closure_custom_calc               => $self->can('custom_cpu_calc'),
            closure_custom_calc_extra_options => { label_ref => 'wsCPUInterruptLoad' },
            manual_keys                       => 1,
            threshold_use                     => 'prct_used',
            output_use                        => 'prct_used',
            output_template                   => 'Interrupt %.2f %%',
            perfdatas                         => [
                { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
            ],
        }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'CPU Usage: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    wsCPUUserLoad      => { oid => '.1.3.6.1.4.1.9303.4.1.1.16' },
    wsCPUNiceLoad      => { oid => '.1.3.6.1.4.1.9303.4.1.1.17' },
    wsCPUSystemLoad    => { oid => '.1.3.6.1.4.1.9303.4.1.1.18' },
    wsCPUInterruptLoad => { oid => '.1.3.6.1.4.1.9303.4.1.1.19' },
    wsCPUIdleLoad      => { oid => '.1.3.6.1.4.1.9303.4.1.1.20' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_systemStats = '.1.3.6.1.4.1.9303.4.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_systemStats,
        start        => $mapping->{wsCPUUserLoad}->{oid},
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{cache_name} = "snmpstandard_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all'));

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check system CPUs (C<User>, C<Nice>, C<System>, C<Idle>, C<Interrupt>)
An average of all CPUs.

=over 8

=item B<--warning-idle>

Threshold in percentage.

=item B<--critical-idle>

Threshold in percentage.

=item B<--warning-interrupt>

Threshold in percentage.

=item B<--critical-interrupt>

Threshold in percentage.

=item B<--warning-nice>

Threshold in percentage.

=item B<--critical-nice>

Threshold in percentage.

=item B<--warning-system>

Threshold in percentage.

=item B<--critical-system>

Threshold in percentage.

=item B<--warning-user>

Threshold in percentage.

=item B<--critical-user>

Threshold in percentage.

=back

=cut
