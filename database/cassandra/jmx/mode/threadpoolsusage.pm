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

package database::cassandra::jmx::mode::threadpoolsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'thpool', type => 1, cb_prefix_output => 'prefix_thpool_output', message_multiple => 'All thread pools are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{thpool} = [
        { label => 'active-tasks', nlabel => 'thread.tasks.active.count', set => {
                key_values => [ { name => 'ActiveTasks_Value' }, { name => 'display' } ],
                output_template => 'Current Active Tasks : %s',
                perfdatas => [
                    { label => 'active_tasks', value => 'ActiveTasks_Value', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'pending-tasks', nlabel => 'thread.tasks.pending.count', set => {
                key_values => [ { name => 'PendingTasks_Value' }, { name => 'display' } ],
                output_template => 'Current Pending Tasks : %s',
                perfdatas => [
                    { label => 'pending_tasks', value => 'PendingTasks_Value', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-completed-tasks', nlabel => 'thread.tasks.completed.count', set => {
                key_values => [ { name => 'CompletedTasks_Value', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Completed Tasks : %s',
                perfdatas => [
                    { label => 'total_completed_tasks', value => 'CompletedTasks_Value', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-blocked-tasks', nlabel => 'thread.tasks.blocked.count', set => {
                key_values => [ { name => 'TotalBlockedTasks_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Blocked Tasks : %s',
                perfdatas => [
                    { label => 'total_blocked_tasks', value => 'TotalBlockedTasks_Count', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-blocked-tasks', nlabel => 'thread.tasks.blocked.current.count', set => {
                key_values => [ { name => 'CurrentlyBlockedTasks_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Currently Blocked Tasks : %s',
                perfdatas => [
                    { label => 'current_blocked_tasks', value => 'CurrentlyBlockedTasks_Count', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"       => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_thpool_output {
    my ($self, %options) = @_;
    
    return "Thread Pool '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{thpool} = {};
    $self->{request} = [
         { mbean => 'org.apache.cassandra.metrics:name=ActiveTasks,path=request,scope=*,type=ThreadPools', attributes => [ { name => 'Value' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=PendingTasks,path=request,scope=*,type=ThreadPools', attributes => [ { name => 'Value' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=CompletedTasks,path=request,scope=*,type=ThreadPools', attributes => [ { name => 'Value' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=TotalBlockedTasks,path=request,scope=*,type=ThreadPools', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=CurrentlyBlockedTasks,path=request,scope=*,type=ThreadPools', attributes => [ { name => 'Count' } ] },
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);
    foreach my $mbean (keys %{$result}) {
        $mbean =~ /scope=(.*?)(?:,|$)/;
        my $scope = $1;
        $mbean =~ /name=(.*?)(?:,|$)/;
        my $name = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $scope !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $scope . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{thpool}->{$scope} = { display => $scope } if (!defined($self->{thpool}->{$scope}));
        foreach (keys %{$result->{$mbean}}) {
            $self->{thpool}->{$scope}->{$name . '_' . $_} = $result->{$mbean}->{$_};
        }
    }
    
    if (scalar(keys %{$self->{thpool}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No thread pool found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "cassandra_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check thread pools usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='active-tasks'

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active-tasks', 'pending-tasks', 'total-completed-tasks', 'total-blocked-tasks',
'current-blocked-tasks'.

=back

=cut
