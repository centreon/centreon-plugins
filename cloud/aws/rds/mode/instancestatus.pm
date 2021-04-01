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

package cloud::aws::rds::mode::instancestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('state : %s', 
        $self->{result_values}->{health}, $self->{result_values}->{replication_health});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'aws_instances', type => 1, cb_prefix_output => 'prefix_awsinstance_output', message_multiple => 'All instances are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-available', set => {
                key_values => [ { name => 'available' }  ],
                output_template => "available : %s",
                perfdatas => [
                    { label => 'total_available', value => 'available', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-failed', set => {
                key_values => [ { name => 'failed' }  ],
                output_template => "failed : %s",
                perfdatas => [
                    { label => 'total_failed', value => 'failed', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-backing-up', set => {
                key_values => [ { name => 'backing-up' }  ],
                output_template => "backing-up : %s",
                perfdatas => [
                    { label => 'total_backing_up', value => 'backing-up', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-maintenance', set => {
                key_values => [ { name => 'maintenance' }  ],
                output_template => "maintenance : %s",
                perfdatas => [
                    { label => 'total_maintenance', value => 'maintenance', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-stopped', set => {
                key_values => [ { name => 'stopped' }  ],
                output_template => "stopped : %s",
                perfdatas => [
                    { label => 'total_stopped', value => 'stopped', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-storage-full', set => {
                key_values => [ { name => 'storage-full' }  ],
                output_template => "storage-full : %s",
                perfdatas => [
                    { label => 'total_storage_full', value => 'storage-full', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{aws_instances} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
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
        "filter-instanceid:s" => { name => 'filter_instanceid' },
        "warning-status:s"    => { name => 'warning_status', default => '' },
        "critical-status:s"   => { name => 'critical_status', default => '' },
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
        available => 0, 'backing-up' => 0, failed => 0, maintenance => 0, stopped => 0, 'storage-full' => 0,
    };
    $self->{aws_instances} = {};
    my $result = $options{custom}->rds_get_instances_status();
    foreach my $instance_id (keys %{$result}) {
        if (defined($self->{option_results}->{filter_instanceid}) && $self->{option_results}->{filter_instanceid} ne '' &&
            $instance_id !~ /$self->{option_results}->{filter_instanceid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance_id . "': no matching filter.", debug => 1);
            next;
        }
            
        $self->{aws_instances}->{$instance_id} = { 
            display => $instance_id, 
            state => $result->{$instance_id}->{state},
        };
        $self->{global}->{$result->{$instance_id}->{state}}++ if (defined($self->{global}->{$result->{$instance_id}->{state}}));
    }
    
    if (scalar(keys %{$self->{aws_instances}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aws rds instance found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check RDS instances status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-available$'

=item B<--filter-instanceid>

Filter by instance id (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-available', 'total-backing-up', 'total-failed', 
'total-maintenance', 'total-stopped', 'total-storage-full'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-available', 'total-backing-up', 'total-failed', 
'total-maintenance', 'total-stopped', 'total-storage-full'.

=back

=cut
