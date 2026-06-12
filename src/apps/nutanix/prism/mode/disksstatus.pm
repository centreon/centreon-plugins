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

package apps::nutanix::prism::mode::disksstatus;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# ─── output personnalisé pour le statut du disque ───────────────────────────
sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "disk '%s' (node: %s, serial: %s) state is '%s', online: %s",
        $self->{result_values}->{id},
        $self->{result_values}->{node},
        $self->{result_values}->{serial},
        $self->{result_values}->{state},
        $self->{result_values}->{online},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'disks',
            type             => 1,
            cb_prefix_output => 'prefix_disk_output',
            message_multiple => 'All disks are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{disks} = [
        # ── Statut opérationnel ──────────────────────────────────────────────
        {
            label           => 'status',
            type            => 2,
            # Un disque sain a disk_status "NORMAL" et online true
            critical_default => '%{state} ne "NORMAL" or %{online} ne "true"',
            set             => {
                key_values => [
                    { name => 'id'     },
                    { name => 'node'   },
                    { name => 'serial' },
                    { name => 'state'  },
                    { name => 'online' },
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # ── Capacité totale (octets) ─────────────────────────────────────────
        {
            label  => 'capacity',
            nlabel => 'disk.capacity.bytes',
            set    => {
                key_values          => [ { name => 'capacity_bytes' }, { name => 'id' } ],
                output_template     => 'capacity: %s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template         => '%d',
                        unit             => 'B',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'id',
                    }
                ]
            }
        },
        # ── Espace libre (octets) ────────────────────────────────────────────
        {
            label  => 'free',
            nlabel => 'disk.free.bytes',
            set    => {
                key_values          => [ { name => 'free_bytes' }, { name => 'id' } ],
                output_template     => 'free: %s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template         => '%d',
                        unit             => 'B',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'id',
                    }
                ]
            }
        },
        # ── Utilisation en pourcentage ───────────────────────────────────────
        {
            label  => 'usage-prct',
            nlabel => 'disk.usage.percentage',
            set    => {
                key_values      => [ { name => 'usage_pct' }, { name => 'id' } ],
                output_template => 'usage: %.2f%%',
                perfdatas       => [
                    {
                        template         => '%.2f',
                        unit             => '%',
                        min              => 0,
                        max              => 100,
                        label_extra_instance => 1,
                        instance_use     => 'id',
                    }
                ]
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    return "Disk '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-node:s'  => { name => 'filter_node' },
            'filter-id:s'    => { name => 'filter_id' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_disks();
    my $entities = $result->{entities} // [];

    $self->{disks} = {};
    for my $disk (@{$entities}) {
        my $id   = $disk->{id}            // $disk->{disk_uuid} // 'unknown';
        my $node = $disk->{node_name}     // $disk->{host_name} // 'N/A';

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '') {
            next if $id !~ /$self->{option_results}->{filter_id}/;
        }
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '') {
            next if $node !~ /$self->{option_results}->{filter_node}/;
        }

        my $capacity = $disk->{disk_size}      // 0;
        my $free     = $disk->{free_space}     // 0;
        # free_space peut être absent selon la version ; on calcule depuis usage si dispo
        if ($free == 0 && defined($disk->{usage_stats})) {
            my $used = $disk->{usage_stats}->{'storage.usage_bytes'} // 0;
            $free = $capacity - $used;
        }
        my $pct = ($capacity > 0) ? (($capacity - $free) / $capacity * 100) : 0;

        $self->{disks}->{$id} = {
            id             => $id,
            node           => $node,
            serial         => $disk->{disk_hardware_config}->{serial_number} // 'N/A',
            state          => $disk->{disk_status}    // 'UNKNOWN',
            online         => defined($disk->{online}) ? ($disk->{online} ? 'true' : 'false') : 'true',
            capacity_bytes => $capacity,
            free_bytes     => ($free >= 0) ? $free : 0,
            usage_pct      => $pct,
        };
    }

    if (scalar(keys %{$self->{disks}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No disk found (check filters).');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix cluster physical disk status and usage through Prism REST API.

=over 8

=item B<--filter-node>

Filter disks by node/host name (regexp). Example: C<--filter-node='^NTNX-A'>

=item B<--filter-id>

Filter disks by disk id (regexp). Example: C<--filter-id='0c2a'>

=item B<--warning-status>

Warning threshold for disk state.
Variables: C<%{id}>, C<%{node}>, C<%{serial}>, C<%{state}>, C<%{online}>

=item B<--critical-status>

Critical threshold for disk state.
Default: C<%{state} ne "NORMAL" or %{online} ne "true">

=item B<--warning-usage-prct>

Warning threshold for disk usage (%).

=item B<--critical-usage-prct>

Critical threshold for disk usage (%). Example: C<--critical-usage-prct=85>

=item B<--warning-capacity>

Warning threshold for disk capacity (bytes).

=item B<--critical-capacity>

Critical threshold for disk capacity (bytes).

=item B<--warning-free>

Warning threshold for disk free space (bytes).

=item B<--critical-free>

Critical threshold for disk free space (bytes).

=back

=cut
