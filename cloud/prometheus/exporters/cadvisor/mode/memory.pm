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

package cloud::prometheus::exporters::cadvisor::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = $self->{result_values}->{perfdata};
    my $value_perf = $self->{result_values}->{used};
    
    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => 'memory.' . $label . '.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    return 'ok' if ($self->{result_values}->{total} <= 0 && $self->{instance_mode}->{option_results}->{units} eq '%');
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{result_values}->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-'. $self->{result_values}->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg;
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("%s: %s (unlimited)", ucfirst($self->{result_values}->{label}), $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        $msg = sprintf("%s: %s (%.2f%% of %s)", ucfirst($self->{result_values}->{label}), $total_used_value . " " . $total_used_unit,
                $self->{result_values}->{prct_used},
                $total_size_value . " " . $total_size_unit);
    }

    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{perfdata} = $options{extra_options}->{perfdata_ref};
    $self->{result_values}->{container} = $options{new_datas}->{$self->{instance} . '_container'};
    $self->{result_values}->{pod} = $options{new_datas}->{$self->{instance} . '_pod'};
    $self->{result_values}->{perf} = $options{new_datas}->{$self->{instance} . '_perf'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_limits'};    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    return 0 if ($self->{result_values}->{total} == 0);

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output',
          message_multiple => 'All containers memory usage are ok' },
    ];

    $self->{maps_counters}->{containers} = [
        { label => 'usage', set => {
                key_values => [ { name => 'limits' }, { name => 'usage' }, { name => 'container' },
                    { name => 'pod' }, { name => 'perf' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { label_ref => 'usage', perfdata_ref => 'used' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'working', set => {
                key_values => [ { name => 'limits' }, { name => 'working' }, { name => 'container' },
                    { name => 'pod' }, { name => 'perf' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { label_ref => 'working', perfdata_ref => 'working' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'cache', nlabel => 'cache.usage.bytes', set => {
                key_values => [ { name => 'cache' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Cache: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'cache', value => 'cache', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
        { label => 'rss', nlabel => 'rss.usage.bytes', set => {
                key_values => [ { name => 'rss' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Rss: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'rss', value => 'rss', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
        { label => 'swap', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'swap' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Swap: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'swap', value => 'swap', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
    ];
}

sub prefix_containers_output {
    my ($self, %options) = @_;

    return "Container '" . $options{instance_value}->{container} . "' [pod: " . $options{instance_value}->{pod} . "] Memory ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "container:s"           => { name => 'container', default => 'container_name!~".*POD.*"' },
        "pod:s"                 => { name => 'pod', default => 'pod_name=~".*"' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "units:s"               => { name => 'units', default => '%' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'limits' => "^container_spec_memory_limit_bytes.*",
        'usage' => "^container_memory_usage_bytes.*",
        'working' => "^container_memory_working_set_bytes.*",
        'cache' => "^container_memory_cache.*",
        'rss' => "^container_memory_rss.*",
        'swap' => "^container_memory_swap.*",
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('container', 'pod')) {
        if ($self->{option_results}->{$label} !~ /^(\w+)[!~=]+\".*\"$/) {
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label . " option as a PromQL filter.");
            $self->{output}->option_exit();
        }
        $self->{labels}->{$label} = $1;
    }

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }    
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{containers} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{usage} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "usage", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{limits} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "limits", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{working} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "working", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{cache} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "cache", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{rss} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "rss", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{swap} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "swap", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        next if (!defined($result->{metric}->{$self->{labels}->{pod}}) || !defined($result->{metric}->{$self->{labels}->{container}}));
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{container} = $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{pod} = $result->{metric}->{$self->{labels}->{pod}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{perf} = $result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check containers memory usage.

=over 8

=item B<--container>

Filter on a specific container (Must be a PromQL filter, Default: 'container_name!~".*POD.*"')

=item B<--pod>

Filter on a specific pod (Must be a PromQL filter, Default: 'pod_name=~".*"')

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'working', 'cache' (B), 'rss' (B), 'swap' (B).

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'working', 'cache' (B), 'rss' (B), 'swap' (B).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - limits: ^container_spec_memory_limit_bytes.*
    - usage: ^container_memory_usage_bytes.*
    - working: ^container_memory_working_set_bytes.*
    - cache: ^container_memory_cache.*
    - rss: ^container_memory_rss.*
    - swap: ^container_memory_swap.*

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='usage'

=back

=cut
