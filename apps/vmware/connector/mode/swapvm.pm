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

package apps::vmware::connector::mode::swapvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return '[connection state ' . $self->{result_values}->{connection_state} . '][power state ' . $self->{result_values}->{power_state} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
         { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{vm} = [
        {
            label => 'status', type => 2, unknown_default => '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i',
            set => {
                key_values => [ { name => 'connection_state' }, { name => 'power_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'swap-in', nlabel => 'vm.swap.in.usage.bytespersecond', set => {
                key_values => [ { name => 'swap_in' }, { name => 'display' } ],
                output_template => 'Swap In: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'swap_in', template => '%s',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
                ],
            }
        },
        { label => 'swap-out', nlabel => 'vm.swap.out.usage.bytespersecond', set => {
                key_values => [ { name => 'swap_out' }, { name => 'display' } ],
                output_template => 'Swap Out: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'swap_out', template => '%s',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
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
        'display-description'  => { name => 'display_description' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vm} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'swapvm'
    );

    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};
        
        $self->{vm}->{$vm_name} = {
            display => $vm_name, 
            connection_state => $response->{data}->{$vm_id}->{connection_state},
            power_state => $response->{data}->{$vm_id}->{power_state},
            swap_in => $response->{data}->{$vm_id}->{'mem.swapinRate.average'},
            swap_out => $response->{data}->{$vm_id}->{'mem.swapoutRate.average'}
        };

        if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }
    }
}

1;

__END__

=head1 MODE

Check virtual machine swap rate usage.

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

=item B<--display-description>

Display virtual machine description.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--warning-*>

Threshold warning.
Can be: 'swap-in', 'swap-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'swap-in', 'swap-out'.

=back

=cut
