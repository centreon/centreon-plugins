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

package cloud::kubernetes::mode::podstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_pod_status_output {
    my ($self, %options) = @_;

    return sprintf("Status is '%s'",
        $self->{result_values}->{status});
}

sub custom_pod_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{namespace} = $options{new_datas}->{$self->{instance} . '_namespace'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};

    return 0;
}

sub custom_container_status_output {
    my ($self, %options) = @_;

    return sprintf("Status is '%s', State is '%s'",
        $self->{result_values}->{status},
        $self->{result_values}->{state});
}

sub custom_container_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{state} = ($options{new_datas}->{$self->{instance} . '_state'} == 1) ? "ready" : "not ready";

    return 0;
}

sub custom_ready_perfdata {
    my ($self, %options) = @_;

    my $value_perf = $self->{result_values}->{ready};
    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => 'containers_ready',
        nlabel => 'containers.ready.count',
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $total_options{total},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
}

sub custom_ready_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{ready};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_ready};
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                  { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_ready_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Containers Ready: %s/%s (%.2f%%)",
        $self->{result_values}->{ready},
        $self->{result_values}->{total},
        $self->{result_values}->{prct_ready});

    return $msg;
}

sub custom_ready_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{ready} = $options{new_datas}->{$self->{instance} . '_containers_ready'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_containers_total'};
    return 0 if ($self->{result_values}->{total} == 0);

    $self->{result_values}->{prct_ready} = $self->{result_values}->{ready} * 100 / $self->{result_values}->{total};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pods', type => 3, cb_prefix_output => 'prefix_pod_output', cb_long_output => 'long_output',
          message_multiple => 'All Pods status are ok', indent_long_output => '    ',
            group => [
                { name => 'global',  type => 0, skipped_code => { -10 => 1 } },
                { name => 'containers', display_long => 1, cb_prefix_output => 'prefix_container_output',
                  message_multiple => 'All containers status are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'containers-ready', set => {
                key_values => [ { name => 'containers_total' }, { name => 'containers_ready' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_ready_calc'),
                closure_custom_output => $self->can('custom_ready_output'),
                closure_custom_perfdata => $self->can('custom_ready_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ready_threshold'),
            }
        },
        { label => 'pod-status', set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'namespace' } ],
                closure_custom_calc => $self->can('custom_pod_status_calc'),
                closure_custom_output => $self->can('custom_pod_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'total-restarts-count', nlabel => 'restarts.total.count', set => {
                key_values => [ { name => 'restarts_total' }, { name => 'name' } ],
                output_template => 'Restarts: %d',
                perfdatas => [
                    { label => 'restarts_count', value => 'restarts_total', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];    
    $self->{maps_counters}->{containers} = [
        { label => 'container-status', set => {
                key_values => [ { name => 'status' }, { name => 'state' } ],
                closure_custom_calc => $self->can('custom_container_status_calc'),
                closure_custom_output => $self->can('custom_container_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'restarts-count', nlabel => 'containers.restarts.count', set => {
                key_values => [ { name => 'restarts' }, { name => 'perf' } ],
                output_template => 'Restarts: %d',
                perfdatas => [
                    { label => 'restarts_count', value => 'restarts', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'perf' },
                ],
            }
        },
    ];
}

sub prefix_pod_output {
    my ($self, %options) = @_;

    return "Pod '" . $options{instance_value}->{name} . "' ";
}

sub prefix_container_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{name} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking pod '" . $options{instance_value}->{name} . "'";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"                 => { name => 'filter_name' },
        "filter-namespace:s"            => { name => 'filter_namespace' },
        "extra-filter:s@"               => { name => 'extra_filter' },
        "warning-pod-status:s"          => { name => 'warning_pod_status', default => '' },
        "critical-pod-status:s"         => { name => 'critical_pod_status', default => '%{status} !~ /running/i' },
        "warning-container-status:s"    => { name => 'warning_container_status', default => '' },
        "critical-container-status:s"   => { name => 'critical_container_status', default => '%{status} !~ /running/i || %{state} !~ /^ready$/' },
        "units:s"                       => { name => 'units', default => '%' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{extra_filter} = {};
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        next if ($filter !~ /(.*)=(.*)/);
        $self->{extra_filter}->{$1} = $2;
    }
    
    $self->change_macros(macros => ['warning_pod_status', 'critical_pod_status',
        'warning_container_status', 'critical_container_status']);    
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{pods} = {};

    my $results = $options{custom}->kubernetes_list_pods();
    
    foreach my $pod (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $pod->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $pod->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne '' &&
            $pod->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $pod->{metadata}->{name} . "': no matching filter namespace.", debug => 1);
            next;
        }
        my $next = 0;
        foreach my $label (keys %{$self->{extra_filter}}) {
            if (!defined($pod->{metadata}->{labels}->{$label}) || $pod->{metadata}->{labels}->{$label} !~ /$self->{extra_filter}->{$label}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $pod->{metadata}->{name} . "': no matching extra filter.", debug => 1);
                $next = 1;
                last;
            }
        }
        next if ($next == 1);

        $self->{pods}->{$pod->{metadata}->{uid}}->{name} = $pod->{metadata}->{name};
        $self->{pods}->{$pod->{metadata}->{uid}}->{global} = {
            name => $pod->{metadata}->{name},
            namespace => $pod->{metadata}->{namespace},
            status => $pod->{status}->{phase},
            containers_total => scalar(@{$pod->{status}->{containerStatuses}}),
            containers_ready => 0,
            restarts_total => 0,
        };

        foreach my $container (@{$pod->{status}->{containerStatuses}}) {
            $self->{pods}->{$pod->{metadata}->{uid}}->{containers}->{$container->{name}} = {
                name => $container->{name},
                status => keys %{$container->{state}},
                state => $container->{ready},
                restarts => $container->{restartCount},
                perf => $pod->{metadata}->{name} . '_' . $container->{name},
            };
            $self->{pods}->{$pod->{metadata}->{uid}}->{global}->{containers_ready}++ if ($container->{ready});
            $self->{pods}->{$pod->{metadata}->{uid}}->{global}->{restarts_total} += $container->{restartCount};
        }
    }
    
    if (scalar(keys %{$self->{pods}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Pods found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check pod status.

=over 8

=item B<--filter-name>

Filter pod name (can be a regexp).

=item B<--filter-namespace>

Filter pod namespace (can be a regexp).

=item B<--extra-filter>

Add an extra filter based on labels (Can be multiple)

Example : --extra-filter='app=mynewapp'

=item B<--warning-pod-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{name}, %{namespace}.

=item B<--critical-pod-status>

Set critical threshold for status (Default: '%{status} !~ /running/i').
Can used special variables like: %{status}, %{name}, %{namespace}.

=item B<--warning-container-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{name}.

=item B<--critical-container-status>

Set critical threshold for status (Default: '%{status} !~ /running/i || %{state} !~ /^ready$/').
Can used special variables like: %{status}, %{state}, %{name}.

=item B<--warning-*>

Threshold warning.
Can be: 'containers-ready', 'total-restarts-count' (count), 'restarts-count' (count).

=item B<--critical-*>

Threshold critical.
Can be: 'containers-ready', 'total-restarts-count' (count), 'restarts-count' (count).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'count').

=back

=cut
