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

package cloud::aws::apigateway::mode::latency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'Latency' => {
        'output' => 'Client Latency',
        'output_unit' => 'ms',
        'perfdata_unit' => 'ms',
        'label' => 'client-latency',
        'nlabel' => 'apigateway.client.latency.milliseconds'
    },
    'IntegrationLatency' => {
        'output' => 'Integration Latency',
        'output_unit' => 'ms',
        'perfdata_unit' => 'ms',
        'label' => 'backend-latency',
        'nlabel' => 'apigateway.backend.latency.milliseconds'
    },
);

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return ucfirst("'" . $options{instance_value}->{display} . "' ");
}

sub prefix_statistics_output {
    my ($self, %options) = @_;
    
    return "Statistic: '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking " . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All API latency metrics are ok', indent_long_output => '    ',
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
                output_template => $metrics_mapping{$metric}->{output} . ': %.2f ' . $metrics_mapping{$metric}->{output_unit},
                perfdatas => [
                    { value => $metric , template => '%.2f', label_extra_instance => 1,
                    perfdata_unit => $metrics_mapping{$metric}->{perfdata_unit} }
                ],
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1,  %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'api-name:s@'     => { name => 'api_name' },
        'filter-metric:s' => { name => 'filter_metric' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $instance (@{$self->{option_results}->{api_name}}) {
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
            namespace => 'AWS/ApiGateway',
            dimensions => [ { Name => 'ApiName', Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period},
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)})
                    && !defined($self->{option_results}->{zeroed}));
                    
                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} =
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ?
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
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

Check metrics related to ApiGateway latencies
Default statistic: 'sum'

=over 8

=item B<--api-name>

Set the API name (Required) (Can be multiple).

=item B<--filter-metric>

Filter metrics (Can be: 'Latency', 'IntegrationLatency') 

=item B<--warning-*> B<--critical-*>

Thresholds warning
star substitution possibilities: client-latency, backend-latency

=back

=cut
