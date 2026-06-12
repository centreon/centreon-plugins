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

package apps::nutanix::prism::mode::snapshots;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use POSIX qw(floor);

# ─── Regroupe les snapshots par VM et calcule l'âge du plus vieux ────────────

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # Compteurs globaux (toutes VMs confondues)
        {
            name => 'global',
            type => 0,
            skipped_code => { -10 => 1 },
        },
        # Compteurs par VM (une ligne de résultat par VM)
        {
            name             => 'vms',
            type             => 1,
            cb_prefix_output => 'prefix_vm_output',
            message_multiple => 'All VM snapshot counts are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{global} = [
        # Nombre total de snapshots sur le cluster
        {
            label  => 'total-count',
            nlabel => 'snapshots.total.count',
            set    => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total snapshots: %d',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{vms} = [
        # Nombre de snapshots par VM
        {
            label  => 'vm-count',
            nlabel => 'vm.snapshots.count',
            set    => {
                key_values      => [ { name => 'count' }, { name => 'vm_name' } ],
                output_template => 'snapshots: %d',
                perfdatas       => [
                    {
                        template         => '%d',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'vm_name',
                    }
                ]
            }
        },
        # Âge du snapshot le plus vieux pour cette VM (en secondes)
        {
            label  => 'oldest-age',
            nlabel => 'vm.snapshot.oldest.age.seconds',
            set    => {
                key_values      => [ { name => 'oldest_age_seconds' }, { name => 'vm_name' } ],
                # output_template utilise une closure pour un affichage lisible
                closure_custom_output => \&custom_oldest_age_output,
                perfdatas             => [
                    {
                        template         => '%d',
                        unit             => 's',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'vm_name',
                    }
                ]
            }
        },
    ];
}

# Affiche l'âge en jours/heures plutôt qu'en secondes brutes
sub custom_oldest_age_output {
    my ($self, %options) = @_;
    my $age_s = $self->{result_values}->{oldest_age_seconds};
    return 'no snapshot' if !defined($age_s) || $age_s < 0;

    my $days  = floor($age_s / 86400);
    my $hours = floor(($age_s % 86400) / 3600);
    my $mins  = floor(($age_s % 3600) / 60);

    my $human = '';
    $human .= "${days}d " if $days > 0;
    $human .= "${hours}h " if $hours > 0;
    $human .= "${mins}m"  if $mins > 0 || $days == 0 && $hours == 0;
    $human = '< 1m' if $human eq '';

    return "oldest snapshot age: $human";
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    return "VM '" . $options{instance_value}->{vm_name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-vm-name:s'       => { name => 'filter_vm_name' },
            # Seuil d'âge max en heures (pratique pour les alertes métier)
            'warning-oldest-age:s'   => { name => 'warning_oldest_age' },
            'critical-oldest-age:s'  => { name => 'critical_oldest_age' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Récupère tous les snapshots d'un coup
    my $result   = $options{custom}->get_snapshots();
    my $entities = $result->{entities} // [];

    # On regroupe par VM
    my %by_vm;
    for my $snap (@{$entities}) {
        my $vm_name = $snap->{vm_name} // $snap->{vm_uuid} // 'unknown';

        if (defined($self->{option_results}->{filter_vm_name}) && $self->{option_results}->{filter_vm_name} ne '') {
            next if $vm_name !~ /$self->{option_results}->{filter_vm_name}/;
        }

        push @{ $by_vm{$vm_name} }, $snap;
    }

    my $total = 0;
    $self->{vms} = {};

    for my $vm_name (sort keys %by_vm) {
        my @snaps  = @{ $by_vm{$vm_name} };
        my $count  = scalar(@snaps);
        $total    += $count;

        # Cherche le snapshot le plus vieux.
        # created_time est en microsecondes depuis l'epoch.
        my $oldest_epoch = undef;
        for my $snap (@snaps) {
            my $ts = $snap->{created_time};   # µs
            next unless defined($ts) && $ts > 0;
            $ts = int($ts / 1000000);         # → secondes
            $oldest_epoch = $ts if !defined($oldest_epoch) || $ts < $oldest_epoch;
        }

        my $oldest_age = defined($oldest_epoch) ? (time() - $oldest_epoch) : -1;

        $self->{vms}->{$vm_name} = {
            vm_name            => $vm_name,
            count              => $count,
            oldest_age_seconds => $oldest_age,
        };
    }

    $self->{global} = { total => $total };
}

1;

__END__

=head1 MODE

Monitor Nutanix VM snapshots (count and age) through Prism REST API.

=over 8

=item B<--filter-vm-name>

Filter by VM name (regexp). Example: C<--filter-vm-name='^Prod'>

=item B<--warning-total-count>

Warning threshold for total snapshot count across all VMs.

=item B<--critical-total-count>

Critical threshold for total snapshot count.

=item B<--warning-vm-count>

Warning threshold for snapshot count per VM.

=item B<--critical-vm-count>

Critical threshold for snapshot count per VM. Example: C<--critical-vm-count=10>

=item B<--warning-oldest-age>

Warning threshold for oldest snapshot age per VM (seconds).
Example (7 days): C<--warning-oldest-age=604800>

=item B<--critical-oldest-age>

Critical threshold for oldest snapshot age per VM (seconds).
Example (30 days): C<--critical-oldest-age=2592000>

=back

=cut
