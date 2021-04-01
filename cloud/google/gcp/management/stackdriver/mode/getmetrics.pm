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

package cloud::google::gcp::management::stackdriver::mode::getmetrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    my $label = $self->{result_values}->{label};
    $label =~ s/\//./g;
    $self->{output}->perfdata_add(
        nlabel => $label,
        instances =>  $self->{result_values}->{aggregation},
        value => $self->{result_values}->{value},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric')
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

    return "Metric '" . $self->{result_values}->{label}  . "' of resource '" . $self->{result_values}->{display}  . "' value is " . $self->{result_values}->{value};
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 1, message_multiple => 'All metrics are ok' }
    ];
    
    $self->{maps_counters}->{metrics} = [
        { label => 'metric', set => {
                key_values => [
                    { name => 'label' }, { name => 'value' },
                    { name => 'aggregation' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold')
            }
        }
    ];    
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'dimension-name:s'     => { name => 'dimension_name' },
        'dimension-operator:s' => { name => 'dimension_operator', default => 'equals' },
        'dimension-value:s'    => { name => 'dimension_value' },
        'instance-key:s'       => { name => 'instance_key' },
        'metric:s'             => { name => 'metric' },
        'api:s'                => { name => 'api' },
        'extra-filter:s@'      => { name => 'extra_filter' },
        'timeframe:s'          => { name => 'timeframe' },
        'aggregation:s@'       => { name => 'aggregation' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{dimension_name}) || $self->{option_results}->{dimension_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --dimension-name <name>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{dimension_value}) || $self->{option_results}->{dimension_value} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --dimension-value <value>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{metric})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --metric <name>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{api})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api <name>.");
        $self->{output}->option_exit();
    }

    $self->{gcp_dimension_name} = $self->{option_results}->{dimension_name};
    $self->{gcp_dimension_operator} = $self->{option_results}->{dimension_operator};
    $self->{gcp_dimension_value} = $self->{option_results}->{dimension_value};
    $self->{gcp_instance_key} = defined($self->{option_results}->{instance_key}) && $self->{option_results}->{instance_key} ne '' ?
        $self->{option_results}->{instance_key} : $self->{option_results}->{dimension_name};
    $self->{gcp_metric} = $self->{option_results}->{metric};
    $self->{gcp_api} = $self->{option_results}->{api};
    $self->{gcp_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;

    if (defined($self->{option_results}->{extra_filter})) {
        $self->{gcp_extra_filters} = [];
        foreach my $extra_filter (@{$self->{option_results}->{extra_filter}}) {
            if ($extra_filter ne '') {
                push @{$self->{gcp_extra_filters}}, $extra_filter;
            }
        }
    }

    my $aggregations = [];
    if (defined($self->{option_results}->{aggregation})) {
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation ne '') {
                push @$aggregations, lc($aggregation);
            }
        }
    }
    $self->{gcp_aggregations} = ['average'];
    if (scalar(@$aggregations) > 0) {
        $self->{gcp_aggregations} = $aggregations;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->gcp_get_metrics(
        dimension_name => $self->{gcp_dimension_name},
        dimension_operator => $self->{gcp_dimension_operator},
        dimension_value => $self->{gcp_dimension_value},
        instance_key => $self->{gcp_instance_key},
        metric => $self->{gcp_metric},
        api => $self->{gcp_api},
        extra_filters => $self->{gcp_extra_filters},
        aggregations => $self->{gcp_aggregations},
        timeframe => $self->{gcp_timeframe}
    );

    $self->{metrics} = {};
    foreach my $instance_name (keys %$results) {
        foreach my $label (keys %{$results->{$instance_name}}) {
            foreach my $aggregation (@{$self->{gcp_aggregations}}) {
                next if (!defined($results->{$instance_name}->{$label}->{$aggregation}));
            
                $self->{metrics}->{ $label . '_' . $aggregation }  = {
                    display => $instance_name,
                    label => $label,
                    aggregation => $aggregation,
                    value => $results->{$instance_name}->{$label}->{$aggregation}
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check GCP metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::management::stackdriver::plugin
--custommode=api --mode=get-metrics --api='compute.googleapis.com' --metric='instance/cpu/utilization'
--dimension-name='metric.labels.instance_name' --dimension-operator=equals --dimension-value=mycomputeinstance --aggregation=average
--timeframe=600 --warning-metric= --critical-metric=

=over 8

=item B<--api>

Set GCP API (Required).

=item B<--metric>

Set stackdriver metric (Required).

=item B<--dimension-name>

Set dimension name (Required).

=item B<--dimension-operator>

Set dimension operator (Default: 'equals'. Can also be: 'regexp', 'starts').

=item B<--dimension-value>

Set dimension value (Required).

=item B<--instance-key>

Set instance key (By default, --dimension-name option is used).

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--warning-metric>

Threshold warning.

=item B<--critical-metric>

Threshold critical.

=item B<--extra-filter>

Set extra filters (Can be multiple).

Example: --extra-filter='metric.labels.mylabel = "LABELBLEUE"'

=back

=cut
