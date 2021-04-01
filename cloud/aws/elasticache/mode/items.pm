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

package cloud::aws::elasticache::mode::items;

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

sub custom_item_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric} . '_' . $options{extra_options}->{stat}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{stat} = $options{extra_options}->{stat};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_item_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => defined($self->{instance_mode}->{option_results}->{per_sec}) ?  $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
                                                  threshold => [ { label => 'critical-' . lc($self->{result_values}->{metric}) . "-" . lc($self->{result_values}->{stat}), exit_litteral => 'critical' },
                                                                 { label => 'warning-' . lc($self->{result_values}->{metric}) . "-" . lc($self->{result_values}->{stat}), exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_item_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . lc($self->{result_values}->{display}) if (!defined($options{extra_instance}) || $options{extra_instance} != 0);

    $self->{output}->perfdata_add(label => lc($self->{result_values}->{metric}) . "_" . lc($self->{result_values}->{stat}) . $extra_label,
				                  unit => defined($self->{instance_mode}->{option_results}->{per_sec}) ? 'items/s' : 'items',
                                  value => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value}),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . lc($self->{result_values}->{metric}) . "-" . lc($self->{result_values}->{stat})),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . lc($self->{result_values}->{metric}) . "-" . lc($self->{result_values}->{stat})),
                                 );
}

sub custom_item_output {
    my ($self, %options) = @_;
    my $msg = "";

    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        $msg = sprintf("%s: %.2f items/s", $self->{result_values}->{metric}, $self->{result_values}->{value_per_sec});
    } else {
        $msg = sprintf("%s: %.2f items", $self->{result_values}->{metric}, $self->{result_values}->{value});
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All items metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $statistic ('minimum', 'maximum', 'average', 'sum') {
        foreach my $metric ('CurrItems') {
            my $entry = { label => lc($metric) . '-' . lc($statistic), set => {
                                key_values => [ { name => $metric . '_' . $statistic }, { name => 'display' }, { name => 'stat' }, { name => 'timeframe' } ],
                                output_template => $metric . ': %d items',
                                perfdatas => [
                                    { label => lc($metric) . '_' . lc($statistic), value => $metric . '_' . $statistic , 
                                      template => '%d', unit => 'items', min => 0, label_extra_instance => 1, instance_use => 'display' },
                                ],
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
        foreach my $metric ('NewItems') {
            my $entry = { label => lc($metric) . '-' . lc($statistic), set => {
                                key_values => [ { name => $metric . '_' . $statistic }, { name => 'display' }, { name => 'stat' }, { name => 'timeframe' } ],
                                closure_custom_calc => $self->can('custom_item_calc'),
                                closure_custom_calc_extra_options => { metric => $metric, stat => $statistic },
                                closure_custom_output => $self->can('custom_item_output'),
                                closure_custom_perfdata => $self->can('custom_item_perfdata'),
                                closure_custom_threshold_check => $self->can('custom_item_threshold'),
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
        "filter-metric:s" => { name => 'filter_metric' },
        "per-sec"         => { name => 'per_sec' },
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

    foreach my $metric ('CurrItems', 'NewItems') {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{aws_metrics}}, $metric;
    }
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
                $self->{metric}->{$instance . "_" . lc($statistic)}->{timeframe} = $self->{aws_timeframe};
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

Check ElastiCache cluster items number (current and new).

Works with Memcached and Redis backends.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::elasticache::plugin --custommode=paws --mode=items --region='eu-west-1'
--name='centreon-front' --statistic='average' --critical-newitems-average='10' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/elasticache-metricscollected.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--name>

Set the cluster name (Required) (Can be multiple).

=item B<--node-id>

Set the node id (Optional).

=item B<--filter-metric>

Filter metrics (Can be: 'CurrItems', 'NewItems') 
(Can be a regexp).

=item B<--warning-$metric$-$statistic$>

Thresholds warning ($metric$ can be: 'curritems', 'newitems',
$statistic$ can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--critical-$metric$-$statistic$>

Thresholds critical ($metric$ can be: 'curritems', 'newitems',
$statistic$ can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
