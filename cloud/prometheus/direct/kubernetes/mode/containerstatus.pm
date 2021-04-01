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

package cloud::prometheus::direct::kubernetes::mode::containerstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s', status is '%s'",
        $self->{result_values}->{state},
        $self->{result_values}->{status});
    $msg .= " [reason: " . $self->{result_values}->{reason} . "]" if (defined($self->{result_values}->{reason}) && $self->{result_values}->{reason} ne "");

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_container'};
    $self->{result_values}->{pod} = $options{new_datas}->{$self->{instance} . '_pod'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{state} = ($options{new_datas}->{$self->{instance} . '_state'} == 1) ? "ready" : "not ready";
    $self->{result_values}->{reason} = $options{new_datas}->{$self->{instance} . '_reason'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_container_output',
          message_multiple => 'All containers status are ok', message_separator => ' - ',
          skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{containers} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'state' }, { name => 'reason' }, { name => 'pod' },
                    { name => 'container' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'restarts-count', nlabel => 'containers.restarts.count', set => {
                key_values => [ { name => 'restarts' }, { name => 'perf' } ],
                output_template => 'Restarts count : %d',
                perfdatas => [
                    { label => 'restarts_count', value => 'restarts', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
    ];
}

sub prefix_container_output {
    my ($self, %options) = @_;

    return "Container '" . $options{instance_value}->{container} . "' [pod: " . $options{instance_value}->{pod} . ", namespace: " . $options{instance_value}->{namespace} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "container:s"           => { name => 'container', default => 'container=~".*"' },
        "pod:s"                 => { name => 'pod', default => 'pod=~".*"' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '%{status} !~ /running/ || %{state} !~ /ready/' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'ready' => '^kube_pod_container_status_ready$',
        'running' => '^kube_pod_container_status_running$',
        'terminated' => '^kube_pod_container_status_terminated$',
        'terminated_reason' => '^kube_pod_container_status_terminated_reason$',
        'waiting' => '^kube_pod_container_status_waiting$',
        'waiting_reason' => '^kube_pod_container_status_waiting_reason$',
        'restarts' => '^kube_pod_container_status_restarts_total$',
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

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{containers} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{ready} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "ready", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{running} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "running", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{terminated} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "terminated", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{terminated_reason} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "terminated_reason", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{waiting} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "waiting", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{waiting_reason} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "waiting_reason", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{restarts} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}, "__name__", "restarts", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        next if (!defined($result->{metric}->{$self->{labels}->{pod}}) || !defined($result->{metric}->{$self->{labels}->{container}}));
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{container} = $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{pod} = $result->{metric}->{$self->{labels}->{pod}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{perf} = $result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}};
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{restarts} = ${$result->{value}}[1] if ($result->{metric}->{__name__} =~ /restarts/);
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{state} = ${$result->{value}}[1] if ($result->{metric}->{__name__} =~ /ready/);
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{status} = $result->{metric}->{__name__} if ($result->{metric}->{__name__} =~ /running|terminated|waiting/ && ${$result->{value}}[1] == 1);
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{reason} = "";
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{reason} = $result->{metric}->{reason} if ($result->{metric}->{__name__} =~ /reason/ && ${$result->{value}}[1] == 1);
        $self->{containers}->{$result->{metric}->{$self->{labels}->{pod}} . "_" . $result->{metric}->{$self->{labels}->{container}}}->{namespace} = $result->{metric}->{namespace};
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check container status.

=over 8

=item B<--container>

Filter on a specific container (Must be a PromQL filter, Default: 'container=~".*"')

=item B<--pod>

Filter on a specific pod (Must be a PromQL filter, Default: 'pod=~".*"')

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{status}, %{state}, %{reason}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /running/ || %{state} !~ /ready/').
Can used special variables like: %{status}, %{state}, %{reason}

=item B<--warning-restarts-count>

Threshold warning for container restarts count.

=item B<--critical-restarts-count>

Threshold critical for container restarts count.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - ready: ^kube_pod_container_status_ready$
    - running: ^kube_pod_container_status_running$
    - terminated: ^kube_pod_container_status_terminated$
    - terminated_reason: ^kube_pod_container_status_terminated_reason$
    - waiting: ^kube_pod_container_status_waiting$
    - waiting_reason: ^kube_pod_container_status_waiting_reason$
    - restarts: ^kube_pod_container_status_restarts_total$

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=back

=cut
