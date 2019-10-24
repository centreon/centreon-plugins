#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use Data::Dumper;

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
        threshold => [ { label => 'critical-metric', exit_litteral => 'critical' },
                       { label => 'warning-metric', exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg = "Metric '" . $self->{result_values}->{label}  . "' of resource '" . $self->{result_values}->{display}  . "' value is " . $self->{result_values}->{value};
    return $msg;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{label} = $options{new_datas}->{$self->{instance} . '_label'};
    $self->{result_values}->{aggregation} = $options{new_datas}->{$self->{instance} . '_aggregation'};
    $self->{result_values}->{perf_label} = $options{new_datas}->{$self->{instance} . '_perf_label'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 0 },
    ];
    
    $self->{maps_counters}->{metrics} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'label' }, { name => 'aggregation' },
                    { name => 'perf_label' }, { name => 'display' } ],
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
        "dimension:s"           => { name => 'dimension' },
        "instance:s"            => { name => 'instance' },
        "metric:s"              => { name => 'metric' },
        "api:s"                 => { name => 'api' },
        "extra-filter:s@"       => { name => 'extra_filter' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{dimension})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --dimension <name>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{instance})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --instance <name>.");
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

    $self->{gcp_dimension} = $self->{option_results}->{dimension};
    $self->{gcp_instance} = $self->{option_results}->{instance};
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
    
    $self->{gcp_aggregation} = ['average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{gcp_aggregation} = [];
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation ne '') {
                push @{$self->{gcp_aggregation}}, lc($aggregation);
            }
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{metrics} = {};

    my ($results, $raw_results) = $options{custom}->gcp_get_metrics(
            dimension => $self->{gcp_dimension},
            instance => $self->{gcp_instance},
            metric => $self->{gcp_metric},
            api => $self->{gcp_api},
            extra_filters => $self->{gcp_extra_filters},
            aggregations => $self->{gcp_aggregation},
            timeframe => $self->{gcp_timeframe},
        );

    foreach my $label (keys %{$results}) {
        foreach my $aggregation (('minimum', 'maximum', 'average', 'total')) {
            next if (!defined($results->{$label}->{$aggregation}));
            $self->{metrics} = {
                display => $self->{gcp_instance},
                label => $label,
                aggregation => $aggregation,
                value => $results->{$label}->{$aggregation},
                perf_label => $label . '_' . $aggregation,
            };
        }
    }       

    $self->{output}->output_add(long_msg => sprintf("Raw data:\n%s", Dumper($raw_results)), debug => 1);
}

1;

__END__

=head1 MODE

Check GCP metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::management::stackdriver::plugin
--custommode=api --mode=get-metrics --api='compute.googleapis.com' --dimension='metric.labels.instance_name'
--metric='instance/cpu/utilization' --instance=mycomputeinstance --aggregation=average
--timeframe=600 --warning-metric= --critical-metric=

=over 8

=item B<--api>

Set GCP API (Required).

=item B<--metric>

Set stackdriver metric (Required).

=item B<--dimension>

Set dimension primary filter (Required).

=item B<--instance>

Set instance name (Required).

=item B<--warning-metric>

Threshold warning.

=item B<--critical-metric>

Threshold critical.

=item B<--extra-filter>

Set extra filters (Can be multiple).

Example: --extra-filter='metric.labels.mylabel = "LABELBLEUE"'

=back

=cut
