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

package cloud::aws::lambda::mode::invocations;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'Duration' => {
        'output' => 'Duration',
        'label' => 'duration',
        'nlabel' => 'lambda.function.duration.milliseconds',
    },
    'Invocations' => {
        'output' => 'Invocations',
        'label' => 'invocations',
        'nlabel' => 'lambda.function.invocations.count',
    },
    'Errors' => {
        'output' => 'Errors',
        'label' => 'errors',
        'nlabel' => 'lambda.function.errors.count',
    },
    'DeadLetterErrors' => {
        'output' => 'Dead Letter Errors',
        'label' => 'deadlettererrors',
        'nlabel' => 'lambda.function.deadlettererrors.count',
    },
    'Throttles' => {
        'output' => 'Throttles',
        'label' => 'throttles',
        'nlabel' => 'lambda.function.throttles.count',
    },
    'IteratorAge' => {
        'output' => 'Iterator Age',
        'label' => 'iteratorage',
        'nlabel' => 'lambda.function.iteratorage.milliseconds',
    }
);

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return "Function '" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;
    
    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking Function '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All functions metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            nlabel => $metrics_mapping{$metric}->{nlabel},
            set => {
                key_values => [ { name => $metric }, { name => 'display' } ],
                output_template => $metrics_mapping{$metric}->{output} . ': %.2f',
                perfdatas => [
                    { value => $metric , template => '%.2f', label_extra_instance => 1 }
                ],
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "name:s@"	      => { name => 'name' },
        "filter-metric:s" => { name => 'filter_metric' },
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
    
    $self->{aws_statistics} = ['Sum', 'Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric (keys %metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{aws_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/Lambda',
            dimensions => [ { Name => 'FunctionName', Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} = defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Lambda invocations metrics.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::lambda::plugin --custommode=paws --mode=invocations --region='eu-west-1'
--name='myFunction' --filter-metric='Duration' --statistic='average' --critical-duration='10' --verbose

See 'https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions-metrics.html' for more informations.

Default statistic: 'sum', 'average'.

=over 8

=item B<--name>

Set the function name (Required) (Can be multiple).

=item B<--filter-metric>

Filter metrics (Can be: 'Duration', 'Invocations', 'Errors',
'DeadLetterErrors', 'Throttles', 'IteratorAge') 
(Can be a regexp).

=item B<--warning-*>

Thresholds warning (Can be: 'invocations', 'errors',
'throttles', 'duration', 'deadlettererrors', 'iteratorage').

=item B<--critical-*>

Thresholds critical (Can be: 'invocations', 'errors',
'throttles', 'duration', 'deadlettererrors', 'iteratorage').

=back

=cut
