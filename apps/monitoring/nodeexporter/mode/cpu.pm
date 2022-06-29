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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_cpu_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_display' }));
    if (!defined($options{old_datas}->{$self->{instance} . '_display' })) {
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

    # use Data::Dumper;
    # print Dumper $self;
    
    # if ($options{old_datas}->{$self->{instance} . '_display' > $options{new_datas}->{$self->{instance} . '_display') {
    #     $options{old_datas}->{$self->{instance} . '_display' = 0;
    # }
    $self->{result_values}->{prct_used} = 
        ($options{new_datas}->{$self->{instance} . '_display'} - 
         $options{old_datas}->{$self->{instance} . '_display'}) * 100 /
        $self->{instance_mode}->{total_cpu};
    
    return 0;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output' },
        { name => 'node_cpu', type => 1, cb_prefix_output => 'prefix_cpu_core_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'count' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'average', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{node_cpu} = [
        { 
            label => 'node-cpu-idle', nlabel => 'node.cpu.idle.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_idle' }],
                closure_custom_calc => $self->can('custom_cpu_calc'), 
                # closure_custom_calc_extra_options => {
                #     display => 'display'
                # },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_idle', value => 'node_cpu_seconds_total_idle', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'node-cpu-iowait', nlabel => 'node.cpu.seconds.iowait.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_iowait' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_iowait', value => 'node_cpu_seconds_total_iowait', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'node-cpu-nice', nlabel => 'node.cpu.seconds.nice.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_nice' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_nice', value => 'node_cpu_seconds_total_nice', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'node-cpu-softirq', nlabel => 'node.cpu.seconds.softirq.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_softirq' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_softirq', value => 'node_cpu_seconds_total_softirq', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { 
            label => 'node-cpu-steal', nlabel => 'node.cpu.seconds.steal.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_steal' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_steal', value => 'node_cpu_seconds_total_steal', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
            { 
            label => 'node-cpu-system', nlabel => 'node.cpu.seconds.system.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_system' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { label => 'node_cpu_seconds_total_system', value => 'node_cpu_seconds_total_system', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
            { 
            label => 'node-cpu-user', nlabel => 'node.cpu.seconds.user.percentage', set => {
                key_values => [ { name => 'node_cpu_seconds_total_user' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    display => 'display'
                },
                output_template => 'usage : %.2f %%',
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

    return $self->{cpu_avg}->{count} . " CPU(s) average usage is ";
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

sub manage_selection {
    my ($self, %options) = @_;

    my $result;
    my $response = $options{custom}->get_metrics();

    foreach my $line (split /\n/, $response) {
        $result->{metrics}->{$1}->{type} = $2 if ($line =~ /^#\sTYPE\s(\w+)\s(.*)$/);
        $result->{metrics}->{$1}->{help} = $2 if ($line =~ /^#\sHELP\s(\w+)\s(.*)$/);

        next if ($line !~ /^[\d\/\s]*([\w.]+)(.*)?\s([\d.+-e]+)$/);
        my ($metric, $dimensions, $value) = ($1, $2, $3);

        $dimensions =~ s/[{}]//g;
        $dimensions =~ s/"/'/g;
        $dimensions =~ s/$options{strip_chars}//g if (defined($options{strip_chars}));
        my %dimensions = ();
        foreach (split /,/, $dimensions) {
            my ($key, $value) = split /=/;
            $dimensions{$key} = $value;
        }

        push @{$result->{metrics}->{$metric}->{data}}, {
            value => centreon::plugins::misc::expand_exponential(value => $value),
            dimensions => \%dimensions,
            dimensions_string => $dimensions
        };
    }
    my @exits;
    my $short_msg = 'All metrics are ok';
    
    my $nometrics = 1;

    foreach my $metric (keys %{$result->{metrics}}) {
        next if ($metric !~ /node_cpu_seconds_total/i);
        
        foreach my $data (@{$result->{metrics}->{$metric}->{data}}) {

            $nometrics = 0;
            my $label = $metric;
            my $cpu_index = $data->{dimensions}->{cpu};
            $cpu_index =~ s/'//g;

            $label .= "_" . $data->{dimensions}->{mode};
            $label =~ s/'//g;

            $self->{node_cpu}->{$label} = {
                display => $cpu_index,
                $label => $data->{value}
            };

            $self->{cache_name} = "testFileblabla";

            $self->{output}->output_add(long_msg => sprintf("Metric '%s' value is '%s' [Help: \"%s\"] [Type: '%s'] [Dimensions: \"%s\"]",
                $metric, $data->{value}, 
                (defined($self->{metrics}->{$metric}->{help})) ? $self->{metrics}->{$metric}->{help} : '-',
                (defined($self->{metrics}->{$metric}->{type})) ? $self->{metrics}->{$metric}->{type} : '-',
                $data->{dimensions_string}));
        }
    }

    if ($nometrics == 1) {
        $self->{output}->add_option_msg(short_msg => "No metrics found.");
        $self->{output}->option_exit();
    }

}

1;

__END__

=head1 MODE

Check CPU based on node exporter metrics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total-cpu', 'total-cpu-mhz', 'cpu'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-cpu', 'total-cpu-mhz', 'cpu'.

=back

=cut
