#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::listnics;

use strict;
use warnings;
use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-vm-name:s' => { name => 'filter_vm_name' },
            'filter-network:s' => { name => 'filter_network' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

# Collect all NICs from the VM list (vm_nics[] is included in v2.0 responses).
sub _collect_nics {
    my ($self, %options) = @_;

    my $vms      = $options{custom}->get_vms();
    my $entities = $vms->{entities} // [];
    my @nics;

    for my $vm (@{$entities}) {
        my $vm_name = $vm->{name} // $vm->{uuid} // 'unknown';
        my $vm_uuid = $vm->{uuid} // '';

        if (defined($self->{option_results}->{filter_vm_name}) && $self->{option_results}->{filter_vm_name} ne '') {
            next if $vm_name !~ /$self->{option_results}->{filter_vm_name}/;
        }

        my $nic_index = 0;
        for my $nic (@{ $vm->{vm_nics} // [] }) {
            my $network = $nic->{network_name} // $nic->{vlan_id} // 'N/A';

            # nic_index tracks the physical position in the VM's NIC array.
            # Skipped NICs still consume an index so nic_id stays stable
            # whether or not --filter-network is active.
            if (defined($self->{option_results}->{filter_network}) && $self->{option_results}->{filter_network} ne '') {
                if ($network !~ /$self->{option_results}->{filter_network}/) {
                    $nic_index++;
                    next;
                }
            }

            push @nics, {
                vm_name   => $vm_name,
                vm_uuid   => $vm_uuid,
                nic_index => $nic_index,
                nic_id    => $vm_name . '_nic' . $nic_index,
                mac       => $nic->{mac_address} // 'N/A',
                network   => $network,
                connected => (defined($nic->{is_connected}) && $nic->{is_connected}) ? 'true' : 'false',
                ip        => (defined($nic->{ip_address}) && $nic->{ip_address} ne '') ? $nic->{ip_address} : 'N/A',
            };
            $nic_index++;
        }
    }

    return \@nics;
}

sub run {
    my ($self, %options) = @_;

    my $nics = $self->_collect_nics(%options);

    for my $nic (@{$nics}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "  vm: %-30s nic_id: %-20s mac: %-20s network: %-20s ip: %-16s connected: %s",
                $nic->{vm_name},
                $nic->{nic_id},
                $nic->{mac},
                $nic->{network},
                $nic->{ip},
                $nic->{connected},
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List of Nutanix VM NICs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    $self->{output}->add_disco_format(
        elements => ['nic_id', 'vm_name', 'vm_uuid', 'nic_index', 'mac', 'network', 'ip', 'connected']
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my $nics = $self->_collect_nics(%options);

    for my $nic (@{$nics}) {
        $self->{output}->add_disco_entry(
            nic_id    => $nic->{nic_id},
            vm_name   => $nic->{vm_name},
            vm_uuid   => $nic->{vm_uuid},
            nic_index => $nic->{nic_index},
            mac       => $nic->{mac},
            network   => $nic->{network},
            ip        => $nic->{ip},
            connected => $nic->{connected},
        );
    }
}

1;

__END__

=head1 MODE

List Nutanix VM NICs for service discovery.

NIC data is extracted from the VM list endpoint (vm_nics[] field) — no extra
API call per VM is needed.

=over 8

=item B<--filter-vm-name>

Filter by VM name (regexp). Example: C<--filter-vm-name='^Prod'>

=item B<--filter-network>

Filter by network/VLAN name (regexp). Example: C<--filter-network='Production'>

=back

=cut
