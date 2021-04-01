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

package cloud::aws::cloudwatch::mode::getmetrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{perf_label},
        value => $self->{result_values}->{value},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric'),
    );
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value},
        threshold => [
            { label => 'critical-metric', exit_litteral => 'critical' },
            { label => 'warning-metric', exit_litteral => 'warning' }
        ]
    );
    return $exit;
}


sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg = "Metric '" . $self->{result_values}->{display}  . "' value is " . $self->{result_values}->{value};
    return $msg;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{perf_label} = $options{new_datas}->{$self->{instance} . '_perf_label'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 1, message_multiple => 'All metrics are ok' },
    ];
    
    $self->{maps_counters}->{metrics} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'perf_label' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
            }
        }
    ];    
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'namespace:s'  => { name => 'namespace' },
        'dimension:s%' => { name => 'dimension' },
        'metric:s@'    => { name => 'metric' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{namespace}) || $self->{option_results}->{namespace} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --namespace option.");
        $self->{output}->option_exit();
    }

    $self->{aws_metrics} = [];
    if (defined($self->{option_results}->{metric})) {
        $self->{aws_metrics} = [@{$self->{option_results}->{metric}}];
    }
    if (scalar(@{$self->{aws_metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --metric option.");
        $self->{output}->option_exit();
    }

    $self->{dimension_name} = '';
    my $append = '';
    $self->{aws_dimensions} = [];
    if (defined($self->{option_results}->{dimension})) {
        foreach (keys %{$self->{option_results}->{dimension}}) {
            push @{$self->{aws_dimensions}}, { Name => $_, Value => $self->{option_results}->{dimension}->{$_} };
            $self->{dimension_name} .= $append . $_ . '.' . $self->{option_results}->{dimension}->{$_};
            $append = '-';
        }
    }
    if ($self->{dimension_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --dimension option.");
        $self->{output}->option_exit();
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

    foreach my $metric_name ($self->{aws_metrics}) {
        foreach my $statistic ($self->{aws_statistics}) {
            my $entry = { label => lc($metric_name) . '-' . $statistic, set => {
                    key_values => [ { name => $metric_name . '_' . $statistic }, { name => 'display' } ],
                    output_template => $metric_name . ' ' . ucfirst($statistic) . ' : %s',
                    perfdatas => [
                        { label => lc($metric_name) . '_' . $statistic, value => $metric_name . '_' . $statistic , template => '%s', 
                          label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
            };
            push @{$self->{maps_counters}->{dimensions}}, $entry;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metric_results = $options{custom}->cloudwatch_get_metrics(
        namespace => $self->{option_results}->{namespace},
        dimensions => $self->{aws_dimensions},
        metrics => $self->{aws_metrics},
        statistics => $self->{aws_statistics},
        timeframe => $self->{aws_timeframe},
        period => $self->{aws_period},
    );

    $self->{metrics} = {};
    foreach my $label (keys %{$metric_results}) {
        foreach my $stat (('minimum', 'maximum', 'average', 'sum')) {
            next if (!defined($metric_results->{$label}->{$stat}));
            
            $self->{metrics}->{$self->{dimension_name} . '_' . $label . '_' . $stat} = {
                display => $self->{dimension_name} . '_' . $label . '_' . $stat,
                value => $metric_results->{$label}->{$stat},
                perf_label => $label . '_' . $stat,
            };
        }
    }
}

1;

__END__

=head1 MODE

Check cloudwatch metrics (same dimension and namespace).

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::plugin --custommode=paws --mode=cloudwatch-get-metrics --region=eu-west-1
--namespace=AWS/EC2 --dimension=InstanceId=i-01622936185e32a45 --metric=CPUUtilization --metric=CPUCreditUsage
--statistic=average --statistic=max –-period=60 --timeframe=600 --warning-metric= --critical-metric=

=over 8

=item B<--namespace>

Set cloudwatch namespace (Required).

=item B<--dimension>

Set cloudwatch dimensions (Required).

=item B<--metric>

Set cloudwatch metrics (Required).

=item B<--warning-metric>

Threshold warning.

=item B<--critical-metric>

Threshold critical.

=back

=cut
