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

package cloud::prometheus::direct::kubernetes::mode::deploymentstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'desired',
        nlabel => 'deployment.replicas.desired.count',
        value => $self->{result_values}->{desired},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'current',
        nlabel => 'deployment.replicas.current.count',
        value => $self->{result_values}->{current},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'available',
        nlabel => 'deployment.replicas.available.count',
        value => $self->{result_values}->{available},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'unavailable',
        nlabel => 'deployment.replicas.unavailable.count',
        value => $self->{result_values}->{unavailable},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'up_to_date',
        nlabel => 'deployment.replicas.uptodate.count',
        value => $self->{result_values}->{up_to_date},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Replicas Desired : %s, Current : %s, Available : %s, Unavailable : %s, Up-to-date : %s",
        $self->{result_values}->{desired},
        $self->{result_values}->{current},
        $self->{result_values}->{available},
        $self->{result_values}->{unavailable},
        $self->{result_values}->{up_to_date});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{desired} = $options{new_datas}->{$self->{instance} . '_desired'};
    $self->{result_values}->{current} = $options{new_datas}->{$self->{instance} . '_current'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_available'};
    $self->{result_values}->{unavailable} = $options{new_datas}->{$self->{instance} . '_unavailable'};
    $self->{result_values}->{up_to_date} = $options{new_datas}->{$self->{instance} . '_up_to_date'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'deployments', type => 1, cb_prefix_output => 'prefix_deployment_output',
            message_multiple => 'All deployments status are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{deployments} = [
        { label => 'status', set => {
                key_values => [ { name => 'desired' }, { name => 'current' }, { name => 'up_to_date' },
                    { name => 'available' }, { name => 'unavailable' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_deployment_output {
    my ($self, %options) = @_;

    return "Deployment '" . $options{instance_value}->{display} . " [namespace: ". $options{instance_value}->{namespace} ."]' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "deployment:s"          => { name => 'deployment', default => 'deployment=~".*"' },
        "warning-status:s"      => { name => 'warning_status', default => '%{up_to_date} < %{desired}' },
        "critical-status:s"     => { name => 'critical_status', default => '%{available} < %{desired}' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'desired' => '^kube_deployment_spec_replicas$',
        'current' => '^kube_deployment_status_replicas$',
        'available' => '^kube_deployment_status_replicas_available$',
        'unavailable' => '^kube_deployment_status_replicas_unavailable$',
        'up_to_date' => '^kube_deployment_status_replicas_updated$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('deployment')) {
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

    $self->{deployments} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{desired} . '",' .
                $self->{option_results}->{deployment} .
                $self->{extra_filter} . '}, "__name__", "desired", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{current} . '",' .
                $self->{option_results}->{deployment} .
                $self->{extra_filter} . '}, "__name__", "current", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{available} . '",' .
                $self->{option_results}->{deployment} .
                $self->{extra_filter} . '}, "__name__", "available", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{unavailable} . '",' .
                $self->{option_results}->{deployment} .
                $self->{extra_filter} . '}, "__name__", "unavailable", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{up_to_date} . '",' .
                $self->{option_results}->{deployment} .
                $self->{extra_filter} . '}, "__name__", "up_to_date", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{deployments}->{$result->{metric}->{$self->{labels}->{deployment}}}->{display} = $result->{metric}->{$self->{labels}->{deployment}};
        $self->{deployments}->{$result->{metric}->{$self->{labels}->{deployment}}}->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
        $self->{deployments}->{$result->{metric}->{$self->{labels}->{deployment}}}->{namespace} = $result->{metric}->{namespace};
    }
    
    if (scalar(keys %{$self->{deployments}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No deployments found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check deployment status.

=over 8

=item B<--deployment>

Filter on a specific deployment (Must be a PromQL filter, Default: 'deployment=~".*"')

=item B<--warning-status>

Set warning threshold for status (Default: '%{up_to_date} < %{desired}')
Can used special variables like: %{display}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}

=item B<--critical-status>

Set critical threshold for status (Default: '%{available} < %{desired}').
Can used special variables like: %{display}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - desired: ^kube_deployment_spec_replicas$
    - current: ^kube_deployment_status_replicas$
    - available: ^kube_deployment_status_replicas_available$
    - unavailable: ^kube_deployment_status_replicas_unavailable$
    - up_to_date: ^kube_deployment_status_replicas_updated$

=back

=cut
