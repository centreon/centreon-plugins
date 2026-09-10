#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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
use centreon::plugins::constants qw(:counters :values);


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => COUNTER_TYPE_GLOBAL,
            cb_prefix_output => 'prefix_cpu_output',
            skipped_code => { NO_VALUE() => 1 }
        },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'user', nlabel => 'cpu.user.utilization.percentage', set => {
            key_values                        => [ { name => 'wsCPUUserLoad' }],
            output_template                   => 'User %.2f %%',
            perfdatas                         =>
                [
                    { value => 'wsCPUUserLoad', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'nice', nlabel => 'cpu.nice.utilization.percentage', set => {
            key_values                        => [ { name => 'wsCPUNiceLoad' }],
            output_template                   => 'Nice %.2f %%',
            perfdatas                         =>
                [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'system', nlabel => 'cpu.system.utilization.percentage', set => {
            key_values                        => [ { name => 'wsCPUSystemLoad' }],
            output_template                   => 'System %.2f %%',
            perfdatas                         =>
                [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'idle', nlabel => 'cpu.idle.utilization.percentage', set => {
            key_values                        => [ { name => 'wsCPUIdleLoad' }],
            output_template                   => 'Idle %.2f %%',
            perfdatas                         =>
                [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
        }
        },
        { label => 'interrupt', nlabel => 'cpu.interrupt.utilization.percentage', set => {
            key_values                        => [ { name => 'wsCPUInterruptLoad' }],
            output_template                   => 'Interrupt %.2f %%',
            perfdatas                         =>
                [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
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

    foreach (keys %{$result}) {
        $result->{$_} = $result->{$_} / 10;
    }

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
