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

package centreon::common::fortinet::fortigate::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0 },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output' },
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' } ],
                output_template => 'CPU(s) average usage is: %.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'average', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'usage: %.2f %%',
                perfdatas => [
                    { value => 'cpu', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ]
            }
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-average', nlabel => 'cluster.cpu.utilization.percentage', display_ok => 0, set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'CPU usage: %.2f %%',
                perfdatas => [
                    { value => 'cpu', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ]
            }
        }
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'cluster'     => { name => 'cluster' },
        'filter-core:s' => { name => 'filter_core' },
    });

    return $self;
}

my $oid_fgSysCpuUsage = '.1.3.6.1.4.1.12356.101.4.1.3';
my $oid_fgProcessorUsage = '.1.3.6.1.4.1.12356.101.4.4.2.1.2'; # some not have
my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1'; # '.0' to have the mode
my $oid_fgHaStatsCpuUsage = '.1.3.6.1.4.1.12356.101.13.2.1.1.3';
my $oid_fgHaStatsHostname = '.1.3.6.1.4.1.12356.101.13.2.1.1.11';

my $maps_ha_mode = { 1 => 'standalone', 2 => 'activeActive', 3 => 'activePassive' };

sub cpu_ha {
    my ($self, %options) = @_;

    $self->{cluster} = {};
    foreach ($options{snmp}->oid_lex_sort(keys %{$options{snmp_result}->{$oid_fgHaStatsCpuUsage}})) {
        /\.(\d+)$/;

        $self->{cluster}->{ $options{snmp_result}->{$oid_fgHaStatsHostname}->{$oid_fgHaStatsHostname . '.' . $1} } = {
            display => $options{snmp_result}->{$oid_fgHaStatsHostname}->{$oid_fgHaStatsHostname . '.' . $1},
            cpu => $options{snmp_result}->{$oid_fgHaStatsCpuUsage}->{$_}
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $table_oids = [ { oid => $oid_fgProcessorUsage }, { oid => $oid_fgSysCpuUsage } ];
    if (defined($self->{option_results}->{cluster})) {
        push @$table_oids, { oid => $oid_fgHaSystemMode },
            { oid => $oid_fgHaStatsCpuUsage },
            { oid => $oid_fgHaStatsHostname };
    }

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => $table_oids, 
        nothing_quit => 1
    );

    my ($cpu, $i) = (0, -1);
    $self->{cpu_core} = {};
    foreach ($options{snmp}->oid_lex_sort(keys %{$snmp_result->{$oid_fgProcessorUsage}})) {
        $i++;
        if (defined($self->{option_results}->{filter_core}) && $self->{option_results}->{filter_core} ne '' &&
            $i !~ /$self->{option_results}->{filter_core}/) {
            $self->{output}->output_add(long_msg => "skipping core cpu '" . $i . "': no matching filter.", debug => 1);
            next;
        }

        $self->{cpu_core}->{$i} = { display => $i, cpu => $snmp_result->{$oid_fgProcessorUsage}->{$_} };
        $cpu += $snmp_result->{$oid_fgProcessorUsage}->{$_};
    }

    my $num_core = scalar(keys %{$self->{cpu_core}});
    $self->{cpu_avg} = {
        average => $num_core > 0 ? $cpu / $num_core : $snmp_result->{$oid_fgSysCpuUsage}->{$oid_fgSysCpuUsage . '.0'}
    };

    if (defined($self->{option_results}->{cluster})) {
        my $ha_mode = $snmp_result->{$oid_fgHaSystemMode}->{$oid_fgHaSystemMode . '.0'};
        my $ha_mode_str = defined($maps_ha_mode->{$ha_mode}) ? $maps_ha_mode->{$ha_mode} : 'unknown';
        $self->{output}->output_add(long_msg => 'high availabily mode is ' . $ha_mode_str);
        if ($ha_mode_str =~ /active/) {
            $self->cpu_ha(snmp => $options{snmp}, snmp_result => $snmp_result);
        }
    }
}

1;

__END__

=head1 MODE

Check system cpu usage (FORTINET-FORTIGATE-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core', 'average', 'cluster-average'.

=item B<--cluster>

Add cluster cpu informations.

=item B<--filter-core>

Core cpu to monitor (can be a regexp).

=back

=cut
