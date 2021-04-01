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

package cloud::aws::elasticache::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    my $node_id = "";
    if (defined($options{instance_value}->{node_id}) && $options{instance_value}->{node_id} ne '') {
        $node_id = "[Node: $options{instance_value}->{node_id}] ";
    }

    return "Cluster '" . $options{instance_value}->{display} . "' " . $node_id . $options{instance_value}->{stat} . " ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All CPU metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $statistic ('minimum', 'maximum', 'average', 'sum') {
        foreach my $metric ('CPUUtilization') {
            my $entry = { label => lc($metric) . '-' . lc($statistic), set => {
                                key_values => [ { name => $metric . '_' . $statistic }, { name => 'display' }, { name => 'stat' } ],
                                output_template => $metric . ': %.2f %%',
                                perfdatas => [
                                    { label => lc($metric) . '_' . lc($statistic), value => $metric . '_' . $statistic , 
                                      template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                                ],
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "name:s@"	      => { name => 'name' },
        "node-id:s" 	  => { name => 'node_id' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{name}) || $self->{option_results}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --name option.");
        $self->{output}->option_exit();
    }

    foreach my $instance (@{$self->{option_results}->{name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;
    
    $self->{aws_statistics} = ['Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    }

    push @{$self->{aws_metrics}}, 'CPUUtilization';
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        push @{$self->{aws_dimensions}}, { Name => 'CacheClusterId', Value => $instance };
        if (defined($self->{option_results}->{node_id}) && $self->{option_results}->{node_id} ne '') {
            push @{$self->{aws_dimensions}}, { Name => 'CacheNodeId', Value => $self->{option_results}->{node_id} };
        }
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/ElastiCache',
            dimensions => $self->{aws_dimensions},
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metric}->{$instance . "_" . lc($statistic)}->{display} = $instance;
                $self->{metric}->{$instance . "_" . lc($statistic)}->{stat} = lc($statistic);
                $self->{metric}->{$instance . "_" . lc($statistic)}->{node_id} = $self->{option_results}->{node_id};
                $self->{metric}->{$instance . "_" . lc($statistic)}->{$metric . "_" . lc($statistic)} = defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check ElastiCache cluster CPU utilization.

Works with Memcached and Redis backends.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::elasticache::plugin --custommode=paws --mode=cpu --region='eu-west-1'
--name='centreon-front' --statistic='average' --critical-cpuutilization-average='90' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/elasticache-metricscollected.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--name>

Set the cluster name (Required) (Can be multiple).

=item B<--node-id>

Set the node id (Optional).

=item B<--warning-cpuutilization-*>

Thresholds warning (* can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--critical-cpuutilization-*>

Thresholds critical (* can be: 'minimum', 'maximum', 'average', 'sum').

=back

=cut
