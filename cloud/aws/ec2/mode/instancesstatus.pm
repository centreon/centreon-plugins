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

package cloud::aws::ec2::mode::instancesstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('state: %s, status: %s', $self->{result_values}->{state}, $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'aws_instances', type => 1, cb_prefix_output => 'prefix_awsinstance_output',
          message_multiple => 'All instances are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pending', nlabel => 'ec2.instances.status.pending.count', set => {
                key_values => [ { name => 'pending' }  ],
                output_template => "Pending : %s",
                perfdatas => [
                    { value => 'pending', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'running', nlabel => 'ec2.instances.status.running.count', set => {
                key_values => [ { name => 'running' }  ],
                output_template => "Running : %s",
                perfdatas => [
                    { value => 'running', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'shuttingdown', nlabel => 'ec2.instances.status.shuttingdown.count', set => {
                key_values => [ { name => 'shutting-down' }  ],
                output_template => "Shutting Down : %s",
                perfdatas => [
                    { value => 'shutting-down', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'terminated', nlabel => 'ec2.instances.status.terminated.count', set => {
                key_values => [ { name => 'terminated' }  ],
                output_template => "Terminated : %s",
                perfdatas => [
                    { value => 'terminated', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'stopping', nlabel => 'ec2.instances.status.stopping.count', set => {
                key_values => [ { name => 'stopping' }  ],
                output_template => "Stopping : %s",
                perfdatas => [
                    { value => 'stopping', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'stopped', nlabel => 'ec2.instances.status.stopped.count', set => {
                key_values => [ { name => 'stopped' }  ],
                output_template => "Stopped : %s",
                perfdatas => [
                    { value => 'stopped', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{aws_instances} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'status' }, { name => 'display' } ],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-instanceid:s" => { name => 'filter_instanceid' },
        "warning-status:s"    => { name => 'warning_status', default => '' },
        "critical-status:s"   => { name => 'critical_status', default => '' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total instances ";
}

sub prefix_awsinstance_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        pending => 0, running => 0, 'shutting-down' => 0, terminated => 0, stopping => 0, stopped => 0,
    };
    $self->{aws_instances} = {};
    my $result = $options{custom}->ec2_get_instances_status();
    foreach my $instance_id (keys %{$result}) {
        if (defined($self->{option_results}->{filter_instanceid}) && $self->{option_results}->{filter_instanceid} ne '' &&
            $instance_id !~ /$self->{option_results}->{filter_instanceid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance_id . "': no matching filter.", debug => 1);
            next;
        }
            
        $self->{aws_instances}->{$instance_id} = { 
            display => $instance_id, 
            state => $result->{$instance_id}->{state},
            status => $result->{$instance_id}->{status},
        };
        $self->{global}->{$result->{$instance_id}->{state}}++;
    }
    
    if (scalar(keys %{$self->{aws_instances}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aws instance found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 instances status.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=instances-status --region='eu-west-1'
--filter-instanceid='.*' --filter-counters='^running$' --critical-running='10' --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceStatus.html' for more informations.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^running$'

=item B<--filter-instanceid>

Filter by instance id (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'pending', 'running', 'shuttingdown', 
'terminated', 'stopping', 'stopped'.

=back

=cut
