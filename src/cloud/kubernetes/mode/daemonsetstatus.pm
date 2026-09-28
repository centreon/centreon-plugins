#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::kubernetes::mode::daemonsetstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:values :counters/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.desired.count',
        value => $self->{result_values}->{desired},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.current.count',
        value => $self->{result_values}->{current},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.available.count',
        value => $self->{result_values}->{available},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        label => 'up_to_date',
        nlabel => 'daemonset.pods.uptodate.count',
        value => $self->{result_values}->{up_to_date},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.ready.count',
        value => $self->{result_values}->{ready},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.misscheduled.count',
        value => $self->{result_values}->{misscheduled},
        instances => $self->{result_values}->{name}
    );
    $self->{output}->perfdata_add(
        nlabel => 'daemonset.pods.unavailable.count',
        value => $self->{result_values}->{unavailable},
        instances => $self->{result_values}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'daemonsets', type => COUNTER_TYPE_INSTANCE, prefix_output => "DaemonSet '%{namespace}/%{name}' ",
            message_multiple => 'All DaemonSets status are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{daemonsets} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{misscheduled} > 0 || %{up_to_date} < %{desired}',
            critical_default => '%{replica_failure} == 1 || %{available} < %{desired}',
            set => {
                key_values => [ { name => 'desired' }, { name => 'current' }, { name => 'up_to_date' },
                    { name => 'available' }, { name => 'unavailable' }, { name => 'ready' }, { name => 'misscheduled' }, { name => 'name' },
                    { name => 'namespace' }, { name => 'replica_failure' } ],
                output_template => 'Pods Desired: %{desired}, Current: %{current}, Available: %{available}, Unavailable: %{unavailable}, Up-to-date: %{up_to_date}, Ready: %{ready}, Misscheduled: %{misscheduled}',
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'       => { redirect => 'include_name' },
        'include-name:s'      => { name => 'include_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'filter-namespace:s'  => { redirect => 'include_namespace' },
        'include-namespace:s' => { name => 'include_namespace' },
        'exclude-namespace:s' => { name => 'exclude_namespace' }
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{daemonsets} = {};

    my $results = $options{custom}->kubernetes_list_daemonsets();
    
    foreach my $daemonset (@{$results}) {
        next if is_excluded($daemonset->{metadata}->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
                || is_excluded($daemonset->{metadata}->{namespace}, $self->{option_results}->{include_namespace}, $self->{option_results}->{exclude_namespace}, output => $self->{output});

        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} } = {
            name => $daemonset->{metadata}->{name},
            namespace => $daemonset->{metadata}->{namespace}
        };

        my $desired =
            $daemonset->{status}->{desiredNumberScheduled} && $daemonset->{status}->{desiredNumberScheduled} =~ /(\d+)/ ? $1 : 0;
        my $available =
            $daemonset->{status}->{numberAvailable} && $daemonset->{status}->{numberAvailable} =~ /(\d+)/ ? $1 : 0;

        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{desired} = $desired;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{current} =
            $daemonset->{status}->{currentNumberScheduled} && $daemonset->{status}->{currentNumberScheduled} =~ /(\d+)/ ? $1 : 0;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{up_to_date} =
            $daemonset->{status}->{updatedNumberScheduled} && $daemonset->{status}->{updatedNumberScheduled} =~ /(\d+)/ ? $1 : 0;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{available} = $available;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{unavailable} = $desired - $available;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{ready} =
            $daemonset->{status}->{numberReady} && $daemonset->{status}->{numberReady} =~ /(\d+)/ ? $1 : 0;
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{misscheduled} =
            $daemonset->{status}->{numberMisscheduled} && $daemonset->{status}->{numberMisscheduled} =~ /(\d+)/ ? $1 : 0;

        my $replica_failure = 0;
        if (ref $daemonset->{status}->{conditions} eq 'ARRAY') {
            foreach my $cond (@{$daemonset->{status}->{conditions}}) {
                if ($cond->{type} eq 'ReplicaFailure' && $cond->{status} eq 'True') {
                    $replica_failure = 1;
                    last
                }
            }
        }
        $self->{daemonsets}->{ $daemonset->{metadata}->{uid} }->{replica_failure} = $replica_failure;
    }
    
    $self->{output}->option_exit(short_msg => "No DaemonSets found.")
        unless %{$self->{daemonsets}};
}

1;

__END__

=head1 MODE

Check DaemonSet status.

=over 8

=item B<--include-name>

Filter DaemonSet name (can be a regexp).

=item B<--exclude-name>

Exclude DaemonSet name (can be a regexp).

=item B<--include-namespace>

Filter DaemonSet namespace (can be a regexp).

=item B<--exclude-namespace>

Exclude DaemonSet namespace (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{misscheduled} > 0 || %{up_to_date} < %{desired}').
You can use the following variables: %{name}, %{namespace}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}, %{ready}, %{misscheduled}, %{replica_failure}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{replica_failure} == 1 || %{available} < %{desired}').
You can use the following variables: %{name}, %{namespace}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}, %{ready}, %{misscheduled}, %{replica_failure}.

=back

=cut
