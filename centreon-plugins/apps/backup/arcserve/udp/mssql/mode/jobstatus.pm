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

package apps::backup::arcserve::udp::mssql::mode::jobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        # To exclude some OK
        if (defined($self->{instance_mode}->{option_results}->{ok_status}) && $self->{instance_mode}->{option_results}->{ok_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{ok_status}") {
            $status = 'ok';
        } elsif (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status : %s (%s) [type: %s] [remote hostname: %s] [vmname: %s] [plan name: %s] [end time: %s]',
        $self->{result_values}->{status} == 1 ? 'ok' : 'failed',
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{rhostname},
        $self->{result_values}->{vmname},
        $self->{result_values}->{plan_name},
        scalar(localtime($self->{result_values}->{end_time}))
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'job', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total jobs : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, 
                    { name => 'type' }, { name => 'rhostname' }, { name => 'vmname' }, { name => 'plan_name' },
                    { name => 'elapsed_time' }, { name => 'end_time' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-server-name:s' => { name => 'filter_server_name' },
        'filter-type:s'        => { name => 'filter_type' },
        'filter-start-time:s'  => { name => 'filter_start_time' },
        'filter-end-time:s'    => { name => 'filter_end_time', default => 86400 },
        'ok-status:s'          => { name => 'ok_status', default => '%{status} == 1' },
        'warning-status:s'     => { name => 'warning_status', default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '%{status} != 1' },
        'timezone:s'           => { name => 'timezone' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
            'ok_status', 'warning_status', 'critical_status'
        ]
    );
    
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "job '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

   my $query = q{
        SELECT
               lj.jobId,
               lj.jobStatus,
               rhostname,
               vmname,
               DATEDIFF(s, '1970-01-01 00:00:00', lj.jobLocalStartTime) as start_time,
               DATEDIFF(s, '1970-01-01 00:00:00', lj.jobLocalEndTime) as end_time,
               ep.name,
               lj.jobType,
               lj.jobStatus
        FROM as_edge_d2dJobHistory_lastJob lj LEFT OUTER JOIN as_edge_policy ep ON lj.planUUID = ep.uuid
            LEFT JOIN as_edge_host h on lj.agentId = h.rhostid
            LEFT JOIN as_edge_vsphere_entity_host_map entityHostMap ON h.rhostid = entityHostMap.hostId
            LEFT JOIN as_edge_vsphere_vm_detail vmDetail ON entityHostMap.entityId=vmDetail.entityId
    };
    $options{sql}->connect();
    $options{sql}->query(query => $query);

    $self->{global} = { total => 0 };
    $self->{job} = {};
    my ($count, $current_time) = (0, time());
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $rhostname = defined($row->{rhostname}) && $row->{rhostname} ne '' ? $row->{rhostname} : 'unknown';
        my $vmname = defined($row->{vmname}) && $row->{vmname} ne '' ? $row->{vmname} : '-';
        my $plan_name = defined($row->{name}) && $row->{name} ne '' ? $row->{name} : 'unknown';
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $row->{jobType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $row->{jobId} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            defined($row->{end_time}) && $row->{end_time} =~ /[0-9]+/ && $row->{end_time} < ($current_time - $self->{option_results}->{filter_end_time})) {
            $self->{output}->output_add(long_msg => "skipping job '" . $row->{jobId} . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            defined($row->{start_time}) && $row->{start_time} =~ /[0-9]+/ && $row->{start_time} < ($current_time - $self->{option_results}->{filter_start_time})) {
            $self->{output}->output_add(long_msg => "skipping job '" . $row->{jobId} . "': start time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_server_name}) && $self->{option_results}->{filter_server_name} ne '' &&
            ($row->{rhostname} !~ /$self->{option_results}->{filter_server_name}/ && $vmname !~ /$self->{option_results}->{filter_server_name}/)) {
            $self->{output}->output_add(long_msg => "skipping job '" . $row->{jobId} . "': no matching filter type.", debug => 1);
            next;
        }

        my $elapsed_time = defined($row->{start_time}) ? $current_time - $row->{start_time} : -1;
        $self->{job}->{$row->{jobId}} = {
            display => $row->{jobId},
            elapsed_time => $elapsed_time, 
            status => $row->{jobStatus},
            type => $row->{jobType},
            rhostname => $rhostname,
            vmname => $vmname,
            plan_name => $plan_name,
            end_time => $row->{end_time},
        };
        
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check job status.

=over 8

=item B<--filter-server-name>

Filter job server name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (Default: 86400).

=item B<--timezone>

Timezone of mssql server (If not set, we use current server execution timezone).

=item B<--ok-status>

Set ok threshold for status (Default: '%{status} == 1')
Can used special variables like: %{display}, %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} == 1')
Can used special variables like: %{display}, %{status}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} != 1').
Can used special variables like: %{display}, %{status}, %{type}

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
