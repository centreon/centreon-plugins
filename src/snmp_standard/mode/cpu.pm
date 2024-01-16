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

package snmp_standard::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    if ($self->{cpu_avg}->{count} > 0) {
        return $self->{cpu_avg}->{count} . ' CPU(s) average usage is ';
    }
    return 'CPU(s) average usage is ';
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output' },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'count' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'use-ucd' => { name => 'use_ucd' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};

    if (defined($self->{option_results}->{use_ucd})) {
        my $oid_ssCpuIdle = '.1.3.6.1.4.1.2021.11.11.0';
        my $snmp_result = $options{snmp}->get_leef(oids => [$oid_ssCpuIdle], nothing_quit => 1);
        $self->{cpu_avg} = {
            average => 100 - $snmp_result->{$oid_ssCpuIdle},
            count => -1
        };
        return ;
    }

    my $oid_cputable = '.1.3.6.1.2.1.25.3.3.1.2';
    my $result = $options{snmp}->get_table(oid => $oid_cputable, nothing_quit => 1);

    my $cpu = 0;
    my $i = 0;
    foreach my $key ($options{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.([0-9]+)$/;
        my $cpu_num = $1;

        $cpu += $result->{$key};
        $self->{cpu_core}->{$i} = {
            display => $i,
            cpu => $result->{$key}
        };

        $i++;
    }

    my $avg_cpu = $cpu / $i;
    $self->{cpu_avg} = {
        average => $avg_cpu,
        count => $i
    };
}

1;

__END__

=head1 MODE

Check system CPUs.
(The average, over the last minute, of the percentage
of time that this processor was not idle)

=over 8

=item B<--use-ucd>

Use UCD mib for cpu average.

=item B<--warning-average>

Warning threshold average CPU utilization. 

=item B<--critical-average>

Critical  threshold average CPU utilization.

=item B<--warning-core>

Warning thresholds for each CPU core

=item B<--critical-core>

Critical thresholds for each CPU core

=back

=cut
