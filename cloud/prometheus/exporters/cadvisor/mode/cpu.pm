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

package cloud::prometheus::exporters::cadvisor::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output',
            message_multiple => 'All containers CPU usage are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{containers} = [
        { label => 'usage', nlabel => 'container.cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Usage: %.2f %%',
                perfdatas => [
                    { label => 'usage', value => 'usage', template => '%.2f',
                      min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
        { label => 'throttled', nlabel => 'container.cpu.throttled.percentage', set => {
                key_values => [ { name => 'throttled' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Throttled: %.2f %%',
                perfdatas => [
                    { label => 'throttled', value => 'throttled', template => '%.2f',
                      min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
    ];
}

sub prefix_containers_output {
    my ($self, %options) = @_;

    return "Container '" . $options{instance_value}->{container} . "' [pod: " . $options{instance_value}->{pod} . "] CPU ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "cpu-attribute:s"       => { name => 'cpu_attribute', default => 'cpu="total"' },
        "container:s"           => { name => 'container', default => 'container_name!~".*POD.*"' },
        "pod:s"                 => { name => 'pod', default => 'pod_name=~".*"' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'throttled' => "^container_cpu_cfs_throttled_seconds_total.*",
        'usage' => "^container_cpu_usage_seconds_total.*",
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

    $self->{prom_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{prom_step} = defined($self->{option_results}->{step}) ? $self->{option_results}->{step} : "5m";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{containers} = {};

    my $results = $options{custom}->query_range(
        queries => [
            'label_replace((irate({__name__=~"' . $self->{metrics}->{usage} . '",' .
                $self->{option_results}->{cpu_attribute} . ',' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}[' . $self->{prom_step} . '])) * 100, "__name__", "usage", "", "")',
            'label_replace((irate({__name__=~"' . $self->{metrics}->{throttled} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}[' . $self->{prom_step} . '])) * 100, "__name__", "throttled", "", "")'
        ],
        timeframe => $self->{prom_timeframe},
        step => $self->{prom_step}
    );

    foreach my $result (@{$results}) {
        next if (!defined($result->{metric}->{$self->{labels}->{pod}}) || !defined($result->{metric}->{$self->{labels}->{container}}));
        my $average = $options{custom}->compute(aggregation => 'average', values => $result->{values});
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{container} = $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{pod} = $result->{metric}->{$self->{labels}->{pod}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{perf} = $result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{$result->{metric}->{__name__}} = $average;
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check containers CPU usage and throttled.

=over 8

=item B<--cpu-attribute>

Set the cpu attribute to match element (Must be a PromQL filter, Default: 'cpu="total"')

=item B<--container>

Filter on a specific container (Must be a PromQL filter, Default: 'container_name!~".*POD.*"')

=item B<--pod>

Filter on a specific pod (Must be a PromQL filter, Default: 'pod_name=~".*"')

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'throttled'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'throttled'.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - throttled: ^container_cpu_cfs_throttled_seconds_total.*
    - usage: ^container_cpu_usage_seconds_total.*

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='throttled'

=back

=cut
