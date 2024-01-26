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

package apps::monitoring::nodeexporter::windows::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_calc {
    my ($self, %options) = @_;

    my $delta_total = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} };
    $self->{result_values}->{used_delta} = 100 * $delta_total / $options{delta_time};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub custom_usage_idle_calc {
    my ($self, %options) = @_;

    my $delta_total = $options{new_datas}->{node_cpu_avg_idle_avg} - $options{old_datas}->{node_cpu_avg_idle_avg};
    $self->{result_values}->{idle_avg_delta} = 100 - ( 100 * $delta_total / $options{delta_time} );

    return 0;
}

sub prefix_node_cpu_avg_output {
    my ($self, %options) = @_;

    return $self->{node_cpu_avg}->{count} . " CPU(s) average usage is ";
}

sub prefix_node_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node_cpu_avg', type => 0, cb_prefix_output => 'prefix_node_cpu_avg_output' },
        { name => 'node_cpu', type => 1, cb_prefix_output => 'prefix_node_cpu_output', message_multiple => 'All CPU types are ok' }
    ];

    $self->{maps_counters}->{node_cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'idle_avg', diff => 1 } , { name => 'count'} ],
                closure_custom_calc => $self->can('custom_usage_idle_calc'),
                output_template => '%.2f %%',
                output_template => 'average usage : %.2f %%', output_use => 'idle_avg_delta', threshold_use => 'idle_avg_delta',
                perfdatas => [
                    { label => 'average', value => 'idle_avg_delta', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{node_cpu} = [
        { 
            label => 'idle', nlabel => 'node.cpu.idle.utilization.percentage', set => {
                key_values => [ { name => 'idle' , diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'idle' },
                output_template => 'idle usage : %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'windows_cpu_time_total_idle', value => 'used_delta', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'dpc', nlabel => 'node.cpu.dpc.utilization.percentage', set => {
                key_values => [ { name => 'dpc', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'dpc' },
                output_template => 'dpc usage : %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'windows_cpu_time_total_dpc', value => 'used_delta', template => '%.2f',
                    min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'interrupt', nlabel => 'node.cpu.interrupt.utilization.percentage', set => {
                key_values => [ { name => 'interrupt', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'interrupt' },
                output_template => 'interrupt usage : %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'windows_cpu_time_total_interrupt', value => 'used_delta', template => '%.2f',
                    min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'privileged', nlabel => 'node.cpu.privileged.utilization.percentage', set => {
                key_values => [ { name => 'privileged', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'privileged' },
                output_template => 'privileged usage : %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'windows_cpu_time_total_privileged', value => 'used_delta', template => '%.2f',
                    min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'user', nlabel => 'node.cpu.user.utilization.percentage', set => {
                key_values => [ { name => 'user', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'user' },
                output_template => 'user usage : %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'windows_cpu_time_total_user', value => 'used_delta', template => '%.2f',
                    min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
  
    $self->{cache_name} = 'windows_nodeexporter' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' . md5_hex('all');
    
    $self->{node_cpu} = {};
    my $cpu_number;
    my $cpu_idle;
    my $avg_cpu_idle;

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /windows_cpu_time_total/i);

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            foreach my $cpu_index ($data->{dimensions}->{core}){
                $self->{node_cpu}->{$cpu_index}->{$data->{dimensions}->{mode}} = $data->{value};
                $self->{node_cpu}->{$cpu_index}->{display} = $data->{dimensions}->{core};

                $cpu_idle += $data->{value} if ($data->{dimensions}->{mode} =~ /idle/i);
            }
        }
    }

    $cpu_number = keys %{$self->{node_cpu}};
    $avg_cpu_idle = $cpu_idle / $cpu_number;

    $self->{node_cpu_avg}->{idle_avg} = $avg_cpu_idle;
    $self->{node_cpu_avg}->{count} = $cpu_number;

    if (scalar(keys %{$self->{node_cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }

}

1;

__END__

=head1 MODE

Check CPU based on node exporter metrics.

=over 8

=item B<--warning-*>

Warning threshold.

Can be: 'average', 'idle', 'dpc', 'user', 'interrupt', 'privileged'

=item B<--critical-*>

Critical threshold.

Can be: 'average', 'idle', 'dpc', 'user', 'interrupt', 'privileged'

=back

=cut