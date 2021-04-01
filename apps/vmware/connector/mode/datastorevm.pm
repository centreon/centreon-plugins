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

package apps::vmware::connector::mode::datastorevm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return '[connection state ' . $self->{result_values}->{connection_state} . '][power state ' . $self->{result_values}->{power_state} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 3, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', indent_long_output => '    ', message_multiple => 'All virtual machines are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_vm', type => 0, skipped_code => { -10 => 1 } },
                { name => 'datastore', cb_prefix_output => 'prefix_datastore_output',  message_multiple => 'All datastores are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i',
            set => {
                key_values => [ { name => 'connection_state' }, { name => 'power_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{global_vm} = [
        { label => 'max-total-latency', nlabel => 'vm.datastore.latency.max.milliseconds', set => {
                key_values => [ { name => 'total_latency' } ],
                output_template => 'max total latency is %s ms',
                perfdatas => [
                    { label => 'max_total_latency', template => '%s', unit => 'ms', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{datastore} = [
        { label => 'read', nlabel => 'vm.datastore.read.usage.iops', set => {
                key_values => [ { name => 'read' } ],
                output_template => '%s read iops',
                perfdatas => [
                    { label => 'riops', template => '%s', unit => 'iops', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'vm.datastore.write.usage.iops', set => {
                key_values => [ { name => 'write' } ],
                output_template => '%s write iops',
                perfdatas => [
                    { label => 'wiops', template => '%s', unit => 'iops', 
                      min => 0, max => 'write', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    my $msg = "Virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }
    $msg .= ' : ';

    return $msg;
}

sub vm_long_output {
    my ($self, %options) = @_;

    my $msg = "checking virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }

    return $msg;
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "datastore '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-hostname:s'        => { name => 'vm_hostname' },
        'filter'               => { name => 'filter' },
        'scope-datacenter:s'   => { name => 'scope_datacenter' },
        'scope-cluster:s'      => { name => 'scope_cluster' },
        'scope-host:s'         => { name => 'scope_host' },
        'filter-description:s' => { name => 'filter_description' },
        'filter-os:s'          => { name => 'filter_os' },
        'filter-uuid:s'        => { name => 'filter_uuid' },
        'display-description'  => { name => 'display_description' },
        'datastore-name:s'     => { name => 'datastore_name' },
        'filter-datastore:s'   => { name => 'filter_datastore' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vm} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastorevm'
    );

    if ($response->{code} == 200) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $response->{short_message}
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};

        $self->{vm}->{$vm_name} = { display => $vm_name, 
            datastore => {}, 
            global => {
                connection_state => $response->{data}->{$vm_id}->{connection_state},
                power_state => $response->{data}->{$vm_id}->{power_state},    
            },
            global_vm => {
                total_latency => $response->{data}->{$vm_id}->{'disk.maxTotalLatency.latest'},
            }
        };

        if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }

        foreach my $ds_name (sort keys %{$response->{data}->{$vm_id}->{datastore}}) {
            $self->{vm}->{$vm_name}->{datastore}->{$ds_name} = { display => $ds_name, 
                read => $response->{data}->{$vm_id}->{datastore}->{$ds_name}->{'disk.numberRead.summation'},
                write => $response->{data}->{$vm_id}->{datastore}->{$ds_name}->{'disk.numberWrite.summation'},
            };
        }
    }
}

1;

__END__

=head1 MODE

Check virtual machine IOPs on datastore(s).

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--datastore-name>

Datastore to check.
If not set, we check all datastores.

=item B<--filter-datastore>

Datastore name is a regexp.

=item B<--display-description>

Display virtual machine description.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like:  %{connection_state}, %{power_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like:  %{connection_state}, %{power_state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'max-total-latency', 'read', 'write'.

=back

=cut
