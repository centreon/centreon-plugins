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

package cloud::prometheus::restapi::mode::targetstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "health is '" . $self->{result_values}->{health} . "'";
    $msg .= " [last error: " . $self->{result_values}->{last_error} . "]" if ($self->{result_values}->{last_error} ne '');
    $msg .= " " . $self->{result_values}->{labels} if ($self->{result_values}->{labels} ne '');

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{last_error} = $options{new_datas}->{$self->{instance} . '_last_error'};
    $self->{result_values}->{labels} = $options{new_datas}->{$self->{instance} . '_labels'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    
    return 0;
}

sub prefix_targets_output {
    my ($self, %options) = @_;
    
    return "Target '" . $options{instance_value}->{display} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Targets ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'targets', type => 1, cb_prefix_output => 'prefix_targets_output', message_multiple => 'All targets status are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'targets.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active: %s',
                perfdatas => [
                    { label => 'active_targets', value => 'active', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'dropped', nlabel => 'targets.dropped.count', set => {
                key_values => [ { name => 'dropped' } ],
                output_template => 'Dropped: %s',
                perfdatas => [
                    { label => 'dropped_targets', value => 'dropped', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'up', nlabel => 'targets.up.count', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'Up: %s',
                perfdatas => [
                    { label => 'up_targets', value => 'up', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'down', nlabel => 'targets.down.count', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'Down: %s',
                perfdatas => [
                    { label => 'down_targets', value => 'down', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'unknown', nlabel => 'targets.unknown.count', set => {
                key_values => [ { name => 'unknown' } ],
                output_template => 'Unknown: %s',
                perfdatas => [
                    { label => 'unknown_targets', value => 'unknown', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{targets} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'health' }, { name => 'last_error' }, { name => 'display' },
                    { name => 'labels' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-label:s@"   => { name => 'filter_label' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{health} !~ /up/' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    foreach my $filter (@{$self->{option_results}->{filter_label}}) {
        next if ($filter !~ /^(\w+),(.*)/);
        $self->{filters}->{$1} = $2;
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
                  
    $self->{global} = { active => 0, dropped => 0, up => 0, down => 0, unknown => 0 };
    $self->{targets} = {};

    my $result = $options{custom}->get_endpoint(url_path => '/targets');

    foreach my $active (@{$result->{activeTargets}}) {
        my $next;
        foreach my $filter (keys %{$self->{filters}}) {
            $next = 1 if (defined($active->{labels}->{$filter}) && $active->{labels}->{$filter} !~ /$self->{filters}->{$filter}/);
        }
        next if ($next);

        $self->{global}->{active}++;
        $self->{targets}->{$active->{scrapeUrl}} = {
            display => $active->{scrapeUrl},
            health => $active->{health},
            last_error => $active->{lastError},

        };
        foreach my $label (keys %{$active->{labels}}) {
            $self->{targets}->{$active->{scrapeUrl}}->{labels} .= "[" . $label . " = " . $active->{labels}->{$label} . "]";
        }
        $self->{global}->{$active->{health}}++;
    }

    foreach my $dropped (@{$result->{droppedTargets}}) {
        $self->{global}->{dropped}++;
    }

    if (scalar(keys %{$self->{targets}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No targets found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check targets status.

=over 8

=item B<--filter-label>

Set filter on label (Regexp, Can be multiple) (Example: --filter-label='job,kube.*').

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{display}, %{health}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{health} !~ /up/').
Can used special variables like: %{display}, %{health}

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'dropped', 'up',
'down', 'unknown'.

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'dropped', 'up',
'down', 'unknown'.

=back

=cut
