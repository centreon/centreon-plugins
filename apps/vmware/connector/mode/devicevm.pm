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

package apps::vmware::connector::mode::devicevm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return '[connection state ' . $self->{result_values}->{connection_state} . '][power state ' . $self->{result_values}->{power_state} . ']';
}

sub custom_device_output {
    my ($self, %options) = @_;

    return sprintf("%s %s device connected",  $self->{result_values}->{device_connected}, $self->{instance_mode}->{option_results}->{device});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-device-connected', nlabel => 'vm.devices.connected.count', set => {
                key_values => [ { name => 'device_connected' } ],
                closure_custom_output => $self->can('custom_device_output'),
                perfdatas => [
                    { label => 'total_device_connected', template => '%s',
                      min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{vm} = [
        {
            label => 'status', type => 2, unknown_default => '%{connection_state} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'connection_state' }, { name => 'power_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'device-connected', nlabel => 'vm.devices.connected.count', set => {
                key_values => [ { name => 'device_connected' }, { name => 'display' } ],
                oclosure_custom_output => $self->can('custom_device_output'),
                perfdatas => [
                    { label => 'device_connected', template => '%s',
                      min => 0, label_extra_instance => 1 }
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
        "vm-hostname:s"         => { name => 'vm_hostname' },
        "filter"                => { name => 'filter' },
        "scope-datacenter:s"    => { name => 'scope_datacenter' },
        "scope-cluster:s"       => { name => 'scope_cluster' },
        "scope-host:s"          => { name => 'scope_host' },
        "filter-description:s"  => { name => 'filter_description' },
        "filter-os:s"           => { name => 'filter_os' },
        "filter-uuid:s"         => { name => 'filter_uuid' },
        "display-description"   => { name => 'display_description' },
        "device:s"              => { name => 'device' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{device}) || $self->{option_results}->{device} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set device option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { device_connected => 0 };
    $self->{vm} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'devicevm'
    );

    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};
        $self->{vm}->{$vm_name} = {
            display => $vm_name, 
            connection_state => $response->{data}->{$vm_id}->{connection_state},
            power_state => $response->{data}->{$vm_id}->{power_state},
            device_connected => $response->{data}->{$vm_id}->{total_device_connected}
        };

        if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }

        $self->{global}->{device_connected} += $self->{vm}->{$vm_name}->{device_connected};
    }
}

1;

__END__

=head1 MODE

Check virtual machine device connected.

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

=item B<--device>

Device to check (Required) (Example: --device='VirtualCdrom').

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i').
Can used special variables like: %{connection_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{connection_state}

=item B<--warning-*>

Threshold warning.
Can be: 'total-device-connected', 'device-connected'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-device-connected', 'device-connected'.

=back

=cut
