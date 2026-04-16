#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::proxmox::ve::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'nodes';
    }
    if ($self->{option_results}->{resource_type} !~ /^node|vm$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_vm {
    my ($self, %options) = @_;

    my $vms = $options{custom}->api_list_vms();

    my $disco_data = [];
    foreach my $vm_id (keys %$vms) {
        my $vm = {};
        $vm->{uuid} = $vm_id;
        $vm->{name} = $vms->{$vm_id}->{Name};
        $vm->{state} = $vms->{$vm_id}->{State};
        $vm->{node_name} = $vms->{$vm_id}->{Node};

        my ($network_ips, $network_interfaces, $osinfo);

        # OSInfo and IPs are retrieved only with a QEMU VM
        if ($vms->{$vm_id}->{Type} eq 'qemu') {
            $osinfo = $options{custom}->api_get_osinfo( Node => $vms->{$vm_id}->{Node}, Vmid => $vms->{$vm_id}->{Vmid});
            $vm->{os_info_name} = $osinfo->{Name};
            $vm->{os_info_prettyname} = $osinfo->{PrettyName};
            $vm->{os_info_version} = $osinfo->{Version};
            $vm->{os_info_machine} = $osinfo->{Machine};
            $vm->{os_info_kernel} = $osinfo->{Kernel};

            ($network_ips, $network_interfaces) = $options{custom}->api_get_network_interfaces( Node => $vms->{$vm_id}->{Node}, Vmid => $vms->{$vm_id}->{Vmid});
        } else {
            $vm->{$_} = '' foreach (qw/os_info_name os_info_prettyname os_info_version os_info_machine os_info_kernel/);
        }

        # provide the list of IP addresses if available or else provide the VM's name as only address
        if ($network_ips && ref $network_ips eq 'ARRAY' && @{$network_ips} > 0) {
            $vm->{ip_addresses} = $network_ips;
        } else {
            $vm->{ip_addresses} = [ $vms->{$vm_id}->{Name}];
        }

        # provide the list of interfaces if available or else provide the VM's name as default address
        if ($network_interfaces && ref $network_interfaces eq 'ARRAY' && @{$network_interfaces} > 0) {
            $vm->{iface_addresses} = $network_interfaces;
        } else {
            $vm->{iface_addresses} = [ { iface => 'default', ip => $vms->{$vm_id}->{Name} } ];
        }

        push @$disco_data, $vm;
    }

    return $disco_data;
}

sub discovery_node {
    my ($self, %options) = @_;

    my $nodes = $options{custom}->api_list_nodes();

    my $disco_data = [];
    foreach my $node_id (keys %$nodes) {
        my $node = {};
        $node->{uuid} = $node_id;
        $node->{name} = $nodes->{$node_id}->{Name};
        $node->{state} = $nodes->{$node_id}->{State};

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'vm') {
        $results = $self->discovery_vm(
            custom => $options{custom}
        );
    } else {
        $results = $self->discovery_node(
            custom => $options{custom}
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--resource-type>

Choose the type of resources to discover (can be: C<vm>, C<node>).

=back

=cut
