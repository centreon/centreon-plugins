#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::vmsnics;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# ─── Output du statut NIC ────────────────────────────────────────────────────
sub custom_nic_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "VM '%s' NIC '%s' (MAC: %s, network: %s) is %s",
        $self->{result_values}->{vm_name},
        $self->{result_values}->{nic_id},
        $self->{result_values}->{mac},
        $self->{result_values}->{network},
        $self->{result_values}->{connected},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'nics',
            type             => 1,
            cb_prefix_output => 'prefix_nic_output',
            message_multiple => 'All VM NICs are connected',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{nics} = [
        # ── Statut de connexion du NIC ───────────────────────────────────────
        {
            label            => 'status',
            type             => 2,
            # Un NIC non connecté est en warning par défaut
            warning_default  => '%{connected} ne "connected"',
            set              => {
                key_values => [
                    { name => 'vm_name'   },
                    { name => 'nic_id'    },
                    { name => 'mac'       },
                    { name => 'network'   },
                    { name => 'connected' },
                ],
                closure_custom_output          => $self->can('custom_nic_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # ── Trafic entrant (octets/s) — disponible via stats de la VM ────────
        {
            label  => 'traffic-in',
            nlabel => 'vm.nic.traffic.in.bytespersecond',
            set    => {
                key_values      => [ { name => 'rx_bytes_rate' }, { name => 'nic_id' }, { name => 'vm_name' } ],
                output_template => 'traffic in: %s/s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template         => '%.2f',
                        unit             => 'B/s',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'nic_id',
                    }
                ]
            }
        },
        # ── Trafic sortant (octets/s) ────────────────────────────────────────
        {
            label  => 'traffic-out',
            nlabel => 'vm.nic.traffic.out.bytespersecond',
            set    => {
                key_values      => [ { name => 'tx_bytes_rate' }, { name => 'nic_id' }, { name => 'vm_name' } ],
                output_template => 'traffic out: %s/s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template         => '%.2f',
                        unit             => 'B/s',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'nic_id',
                    }
                ]
            }
        },
    ];
}

sub prefix_nic_output {
    my ($self, %options) = @_;
    return "NIC '" . $options{instance_value}->{nic_id} . "' (VM: " . $options{instance_value}->{vm_name} . ") ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-vm-name:s'  => { name => 'filter_vm_name' },
            'filter-mac:s'      => { name => 'filter_mac' },
            'filter-network:s'  => { name => 'filter_network' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # On itère sur toutes les VMs pour récupérer leurs NICs.
    # L'API v2.0 expose les NICs dans la réponse de la liste des VMs
    # via le champ vm_nics[] — pas besoin d'un appel par VM.
    my $vms_result = $options{custom}->get_vms();
    my $vms        = $vms_result->{entities} // [];

    $self->{nics} = {};

    for my $vm (@{$vms}) {
        my $vm_name = $vm->{name} // $vm->{uuid} // 'unknown';
        my $vm_uuid = $vm->{uuid} // '';

        if (defined($self->{option_results}->{filter_vm_name}) && $self->{option_results}->{filter_vm_name} ne '') {
            next if $vm_name !~ /$self->{option_results}->{filter_vm_name}/;
        }

        my $nics = $vm->{vm_nics} // [];
        my $stats = $vm->{stats} // {};

        # Les stats réseau sont agrégées au niveau VM dans v2.0.
        # network_received_bytes et network_transmitted_bytes sont en octets cumulés ;
        # Centreon n'a pas d'état persistant ici, on utilise les valeurs "rate" si dispo.
        # Si absent, on met 0 (non disponible).
        my $rx_rate = $stats->{'nic.received_bytes_rate'}      // 0;
        my $tx_rate = $stats->{'nic.transmitted_bytes_rate'}   // 0;

        my $nic_index = 0;
        for my $nic (@{$nics}) {
            my $mac     = $nic->{mac_address}   // 'unknown';
            my $network = $nic->{network_name}  // $nic->{vlan_id} // 'N/A';
            my $nic_id  = $vm_name . '_nic' . $nic_index;

            if (defined($self->{option_results}->{filter_mac}) && $self->{option_results}->{filter_mac} ne '') {
                $nic_index++;
                next if $mac !~ /$self->{option_results}->{filter_mac}/i;
            }
            if (defined($self->{option_results}->{filter_network}) && $self->{option_results}->{filter_network} ne '') {
                $nic_index++;
                next if $network !~ /$self->{option_results}->{filter_network}/;
            }

            # is_connected est un booléen dans l'API Nutanix v2.0
            my $connected = (defined($nic->{is_connected}) && $nic->{is_connected}) ? 'connected' : 'disconnected';

            $self->{nics}->{$nic_id} = {
                vm_name      => $vm_name,
                nic_id       => $nic_id,
                mac          => $mac,
                network      => $network,
                connected    => $connected,
                # Les rates réseau ne sont pas par NIC dans v2.0 — on les attribue
                # au premier NIC de la VM (index 0). Les autres NIC ont 0.
                rx_bytes_rate => ($nic_index == 0) ? $rx_rate : 0,
                tx_bytes_rate => ($nic_index == 0) ? $tx_rate : 0,
            };

            $nic_index++;
        }
    }

    if (scalar(keys %{$self->{nics}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No NIC found (check filters).');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix VM NIC connectivity and traffic through Prism REST API.

Note: In Prism API v2.0, network traffic stats are aggregated at VM level,
not per NIC. Traffic counters are attributed to the first NIC (index 0) of
each VM. For per-NIC traffic, use Prism Central API v3 with metric queries.

=over 8

=item B<--filter-vm-name>

Filter by VM name (regexp). Example: C<--filter-vm-name='^Prod'>

=item B<--filter-mac>

Filter NICs by MAC address (regexp, case-insensitive). Example: C<--filter-mac='^50:6b'>

=item B<--filter-network>

Filter NICs by network/VLAN name (regexp). Example: C<--filter-network='Production'>

=item B<--warning-status>

Warning threshold for NIC connection status.
Default: C<%{connected} ne "connected">

Variables: C<%{vm_name}>, C<%{nic_id}>, C<%{mac}>, C<%{network}>, C<%{connected}>

=item B<--critical-status>

Critical threshold for NIC connection status.

=item B<--warning-traffic-in>

Warning threshold for inbound traffic (B/s).

=item B<--critical-traffic-in>

Critical threshold for inbound traffic (B/s).

=item B<--warning-traffic-out>

Warning threshold for outbound traffic (B/s).

=item B<--critical-traffic-out>

Critical threshold for outbound traffic (B/s).

=back

=cut
