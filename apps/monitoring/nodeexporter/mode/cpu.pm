#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::nodeexporter::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node_cpu', type => 1, cb_prefix_output => 'prefix_node_cpu_output', message_multiple => 'All CPU types are ok' }
    ];

    $self->{maps_counters}->{node_cpu} = [
        { 
            label => 'idle', nlabel => 'node.cpu.idle.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_idle' }],
                output_template => 'CPU idle usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_idle', value => 'node_cpu_seconds_total_idle', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
                label => 'iowait', nlabel => 'node.cpu.seconds.iowait.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_iowait' } ],
                    output_template => 'CPU iowait usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_iowait', value => 'node_cpu_seconds_total_iowait', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'irq', nlabel => 'node.cpu.seconds.irq.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_irq' } ],
                    output_template => 'CPU irq usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_irq', value => 'node_cpu_seconds_total_irq', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'nice', nlabel => 'node.cpu.seconds.nice.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_nice' } ],
                    output_template => 'CPU nice usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_nice', value => 'node_cpu_seconds_total_nice', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'softirq', nlabel => 'node.cpu.seconds.softirq.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_softirq' } ],
                    output_template => 'CPU softirq usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_softirq', value => 'node_cpu_seconds_total_softirq', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'steal', nlabel => 'node.cpu.seconds.steal.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_steal' } ],
                    output_template => 'CPU steal usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_steal', value => 'node_cpu_seconds_total_steal', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'system', nlabel => 'node.cpu.seconds.system.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_system' } ],
                    output_template => 'CPU system usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_system', value => 'node_cpu_seconds_total_system', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { 
                label => 'user', nlabel => 'node.cpu.seconds.user.percentage', set => {
                    key_values => [ { name => 'node_cpu_seconds_total_user' } ],
                    output_template => 'CPU user usage : %.2f %%',
                    perfdatas => [
                        { label => 'node_cpu_seconds_total_user', value => 'node_cpu_seconds_total_user', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        }
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return "Total CPU(s) average usage is ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });

    

    return $self;
}

sub convert_buffer_to_percentage {
    my (%options) = @_;

    print $options{data_value};

    foreach my $key (keys %options)
    {
        print "KEY : $key , VALUE : $options{$key}\n";
    }

    # $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    # $self->{statefile_value}->check_options(%options);
    # $self->{statefile_value}->read(statefile => $self->{cache_name});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
  
    $self->{cache_name} = 'linux_nodeexporter' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_channel}) ? md5_hex($self->{option_results}->{filter_channel}) : md5_hex('all'));

    $self->{node_cpu} = {};
    foreach my $metric (keys %{$metrics}) {
        next if ($metric !~ /node_cpu_seconds_total/i);

        foreach my $data (@{$metrics->{$metric}->{data}}) {
            my $label = $metric;
            my $cpu_index = $data->{dimensions}->{cpu};
            $cpu_index =~ s/'//g;

            $label .= "_" . $data->{dimensions}->{mode};
            $label =~ s/'//g;

            my $data_value = $data->{value};

            convert_buffer_to_percentage(data_value => $data_value);

            # $self->{node_cpu}->{$cpu_index}->{$label} = $data->{value};
        }
    }
    # convert_buffer_to_percentage($self);
}

1;

__END__

=head1 MODE

Check CPU based on node exporter metrics.

=over 8

=item B<--warning-*>

=item B<--critical-*>

=back

=cut