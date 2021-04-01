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

package cloud::prometheus::direct::kubernetes::mode::namespacestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status phase is '%s'", $self->{result_values}->{phase});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{phase} = $options{new_datas}->{$self->{instance} . '_phase'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', cb_prefix_output => 'prefix_global_output' },
        { name => 'namespaces', type => 1, cb_prefix_output => 'prefix_namespace_output',
          message_multiple => 'All namespaces status are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'namespaces.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active : %d',
                perfdatas => [
                    { label => 'active', value => 'active', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'terminating', nlabel => 'namespaces.terminating.count', set => {
                key_values => [ { name => 'terminating' } ],
                output_template => 'Terminating : %d',
                perfdatas => [
                    { label => 'terminating', value => 'terminating', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{namespaces} = [
        { label => 'status', set => {
                key_values => [ { name => 'phase' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{namespaces}}) > 1 ? return(0) : return(1);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Namespaces ";
}

sub prefix_namespace_output {
    my ($self, %options) = @_;

    return "Namespace '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "namespace:s"           => { name => 'namespace', default => 'namespace=~".*"' },
        "phase:s"               => { name => 'phase', default => 'phase=~".*"' },
        "warning-status:s"      => { name => 'warning_status' },
        "critical-status:s"     => { name => 'critical_status', default => '%{phase} !~ /Active/' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'status' => '^kube_namespace_status_phase$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('namespace', 'phase')) {
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

    $self->{global} = { active => 0, terminating => 0 };
    $self->{namespaces} = {};

    my $results = $options{custom}->query(
        queries => [
            '{__name__=~"' . $self->{metrics}->{status} . '",' .
                $self->{option_results}->{namespace} .
                $self->{extra_filter} . '}'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{namespaces}->{$result->{metric}->{$self->{labels}->{namespace}}}->{display} = $result->{metric}->{$self->{labels}->{namespace}};
        $self->{namespaces}->{$result->{metric}->{$self->{labels}->{namespace}}}->{$self->{labels}->{phase}} = $result->{metric}->{$self->{labels}->{phase}} if (${$result->{value}}[1] == 1);
        $self->{global}->{lc($result->{metric}->{$self->{labels}->{phase}})}++ if (${$result->{value}}[1] == 1);
    }

    if (scalar(keys %{$self->{namespaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No namespaces found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check namespace status phase.

=over 8

=item B<--namespace>

Filter on a specific namespace (Must be a PromQL filter, Default: 'namespace=~".*"')

=item B<--phase>

Filter on a specific phase (Must be a PromQL filter, Default: 'phase=~".*"')

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{display}, %{phase}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{phase} !~ /Active/').
Can used special variables like: %{display}, %{phase}

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - status: ^kube_namespace_status_phase$

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=back

=cut
