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

package apps::vmware::connector::mode::datastoreiops;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'accessible ' . $self->{result_values}->{accessible};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datastore', type => 3, cb_prefix_output => 'prefix_datastore_output', cb_long_output => 'datastore_long_output', indent_long_output => '    ', message_multiple => 'All datastores are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_iops', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vm', cb_prefix_output => 'prefix_vm_output',  message_multiple => 'All virtual machines IOPs are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{accessible} !~ /^true|1$/i', 
            set => {
                key_values => [ { name => 'accessible' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{global_iops} = [
        { label => 'read', nlabel => 'datastore.read.usage.iops', set => {
                key_values => [ { name => 'read' } ],
                output_template => '%s read iops',
                perfdatas => [
                    { label => 'riops', template => '%s', unit => 'iops', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'datastore.write.usage.iops', set => {
                key_values => [ { name => 'write' } ],
                output_template => '%s write iops',
                perfdatas => [
                    { label => 'wiops', template => '%s', unit => 'iops', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{vm} = [
        { label => 'read-vm', nlabel => 'datastore.vm.read.usage.iops', set => {
                key_values => [ { name => 'read' } ],
                output_template => '%s read iops',
                perfdatas => [
                    { label => 'vm_riops', template => '%s', unit => 'iops', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-vm', nlabel => 'datastore.vm.write.usage.iops', set => {
                key_values => [ { name => 'write' } ],
                output_template => '%s write iops',
                perfdatas => [
                    { label => 'vm_wiops', template => '%s', unit => 'iops', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{display} . "' : ";
}

sub datastore_long_output {
    my ($self, %options) = @_;

    return "checking datastore '" . $options{instance_value}->{display} . "'";
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "virtual machine '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'datastore-name:s'   => { name => 'datastore_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'detail-iops-min:s'  => { name => 'detail_iops_min', default => 50 }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{datastore} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastoreiops'
    );

    if ($response->{code} == 200) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $response->{short_message}
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};
        $self->{datastore}->{$ds_name} = { display => $ds_name, 
            vm => {}, 
            global => {
                accessible => $response->{data}->{$ds_id}->{accessible},    
            },
            global_iops => {
                write => $response->{data}->{$ds_id}->{'disk.numberWrite.summation'},
                read => $response->{data}->{$ds_id}->{'disk.numberRead.summation'},
            }, 
        };
        
        foreach my $vm_name (sort keys %{$response->{data}->{$ds_id}->{vm}}) {
            $self->{datastore}->{$ds_name}->{vm}->{$vm_name} = { 
                display => $vm_name, 
                write => $response->{data}->{$ds_id}->{vm}->{$vm_name}->{'disk.numberWrite.summation'},
                read => $response->{data}->{$ds_id}->{vm}->{$vm_name}->{'disk.numberRead.summation'},
            };
        }
    }
}

1;

__END__

=head1 MODE

Check datastore IOPs.

=over 8

=item B<--datastore-name>

datastore name to list.

=item B<--filter>

Datastore name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--detail-iops-min>

Only display VMs with iops higher value (default: 50).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{accessible} !~ /^true|1$/i').
Can used special variables like: %{accessible}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', 'read-vm', 'write-vm'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', 'read-vm', 'write-vm'.

=back

=cut
