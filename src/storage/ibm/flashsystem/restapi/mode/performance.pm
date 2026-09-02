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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Performance de la baie : latence, debit, IOPS et charge processeur.
#
# lssystemstats rend une liste de compteurs { stat_name, stat_current,
# stat_peak, stat_peak_time }. On expose la valeur courante en metrique et le
# pic en donnee complementaire : sur un echantillonnage a cinq minutes, le pic
# dit ce que la moyenne efface.
#
# Aucun compteur ne porte de seuil par defaut : les IOPS, le debit et le
# processeur n'ont pas de bonne valeur dans l'absolu — ils se reglent sur
# l'observe. La latence est le seul indicateur a norme physique (sur du
# tout-flash, quelques ms sont normales, quelques dizaines non) : la doc
# suggere 10/20 ms comme point de depart, a poser via --warning-latency /
# --critical-latency dans la macro EXTRAOPTIONS du modele Latency, en UAT.
#
# IBM Storage Insights Pro garde un an d'historique et des dizaines de
# metriques : la metrologie fine vit la-bas. Ce mode existe pour l'ALERTE, qui
# doit naitre dans Centreon parce que c'est lui qui parle a ServiceNow.
#

package storage::ibm::flashsystem::restapi::mode::performance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

# Correspondance entre les compteurs de la baie et les metriques publiees.
# 'scale' convertit vers l'unite attendue par Centreon ; les Mo/s de la baie
# deviennent des octets par seconde.
my $MEASURES = [
    { stat => 'vdisk_ms',           key => 'latency',            unit => 'ms' },
    { stat => 'vdisk_r_ms',         key => 'read_latency',       unit => 'ms' },
    { stat => 'vdisk_w_ms',         key => 'write_latency',      unit => 'ms' },
    { stat => 'vdisk_io',           key => 'iops',               unit => 'iops' },
    { stat => 'vdisk_mb',           key => 'bandwidth',          unit => 'B/s', scale => 1024 * 1024 },
    { stat => 'cpu_pc',             key => 'cpu',                unit => '%' },
    { stat => 'compression_cpu_pc', key => 'compression_cpu',    unit => '%' },
    { stat => 'write_cache_pc',     key => 'write_cache',        unit => '%' },
    { stat => 'total_cache_pc',     key => 'total_cache',        unit => '%' },
    # Cote arriere : utile pour distinguer une latence vue par les hotes d'une
    # latence reellement produite par les disques.
    { stat => 'mdisk_ms',           key => 'backend_latency',    unit => 'ms' },
    { stat => 'drive_ms',           key => 'drive_latency',      unit => 'ms' },
    { stat => 'fc_io',              key => 'fc_iops',            unit => 'iops' },
    { stat => 'fc_mb',              key => 'fc_bandwidth',       unit => 'B/s', scale => 1024 * 1024 }
];

sub prefix_system_output {
    my ($self, %options) = @_;

    return 'Performance: ';
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 0, cb_prefix_output => 'prefix_system_output' },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output',
          message_multiple => 'All node CPUs are ok', skipped_code => { -10 => 1 } }
    ];

    # Il n'y a pas de « load average » sur Storage Virtualize : l'equivalent
    # le plus proche est la charge CPU PAR CANISTER (lsnodecanisterstats).
    # Sur un actif/actif a deux noeuds, c'est le desequilibre qui parle : un
    # noeud qui porte tout pendant que l'autre dort signale une bascule ou
    # des chemins malades — invisible dans le CPU global, qui moyenne.
    #
    # Le label 'node-cpu' est choisi pour que le filtre --filter-counters=cpu
    # du service Cpu l'attrape tel quel : la declinaison arrive dans le bon
    # service sans toucher aux modeles Centreon.
    $self->{maps_counters}->{nodes} = [
        { label => 'node-cpu', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100,
                                 label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];

    $self->{maps_counters}->{system} = [
        # La latence est le seul compteur livre avec des seuils : sur du
        # tout-flash, au-dela de quelques dizaines de millisecondes le probleme
        # est reel quelle que soit la charge.
        { label => 'latency', nlabel => 'system.io.latency.milliseconds',
          set => {
                key_values => [ { name => 'latency' } ],
                output_template => 'latency %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'read-latency', nlabel => 'system.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'write-latency', nlabel => 'system.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'iops', nlabel => 'system.io.usage.iops', set => {
                key_values => [ { name => 'iops' } ],
                output_template => '%s IOPS',
                perfdatas => [ { template => '%s', unit => 'iops', min => 0 } ]
            }
        },
        # output_change_bytes rend un couple (valeur, unite) : sans le second
        # %s, la sortie affiche « bandwidth 1.34 » et l'unite disparait.
        #
        # Et il faut le mode 1, pas 2 : le mode 2 est prevu pour le reseau, ou
        # l'on compte des BITS, et rend une unite en « b » — « 1.74 Gb/s » pour
        # une valeur qui est en octets par seconde. Un facteur huit dans la
        # tete du lecteur. Le mode 1 rend « GB », ce que la mesure est vraiment.
        { label => 'bandwidth', nlabel => 'system.io.usage.bytespersecond', set => {
                key_values => [ { name => 'bandwidth' } ],
                output_template => 'bandwidth %s %s/s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%s', unit => 'B/s', min => 0 } ]
            }
        },
        { label => 'cpu', nlabel => 'system.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'compression-cpu', nlabel => 'system.cpu.compression.utilization.percentage', set => {
                key_values => [ { name => 'compression_cpu' } ],
                output_template => 'compression cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'write-cache', nlabel => 'system.cache.write.usage.percentage', set => {
                key_values => [ { name => 'write_cache' } ],
                output_template => 'write cache %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'total-cache', nlabel => 'system.cache.total.usage.percentage', set => {
                key_values => [ { name => 'total_cache' } ],
                output_template => 'total cache %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'backend-latency', nlabel => 'system.backend.latency.milliseconds', set => {
                key_values => [ { name => 'backend_latency' } ],
                output_template => 'backend %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'drive-latency', nlabel => 'system.drive.latency.milliseconds', set => {
                key_values => [ { name => 'drive_latency' } ],
                output_template => 'drives %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'fc-iops', nlabel => 'system.fc.usage.iops', set => {
                key_values => [ { name => 'fc_iops' } ],
                output_template => 'fc %s IOPS',
                perfdatas => [ { template => '%s', unit => 'iops', min => 0 } ]
            }
        },
        { label => 'fc-bandwidth', nlabel => 'system.fc.usage.bytespersecond', set => {
                key_values => [ { name => 'fc_bandwidth' } ],
                output_template => 'fc %s %s/s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%s', unit => 'B/s', min => 0 } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-peaks' => { name => 'add_peaks' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # statistics_status a 'off' fige lssystemstats sans le signaler : les
    # valeurs restent lisibles mais ne bougent plus. Mieux vaut le dire que
    # publier une courbe morte.
    my $system = $options{custom}->request(command => 'lssystem')->[0];
    if (defined($system->{statistics_status}) && $system->{statistics_status} !~ /^on$/i) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Statistics collection is ' . $system->{statistics_status}
                . ' on this system: the counters below would be stale.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my %stats;
    foreach my $entry (@{ $options{custom}->request(command => 'lssystemstats') }) {
        next unless (ref $entry eq 'HASH' && defined($entry->{stat_name}));
        $stats{ $entry->{stat_name} } = $entry;
    }

    # Charge CPU par canister. request_optional : un firmware qui ne rendrait
    # pas la commande prive du detail par noeud, pas du controle entier.
    $self->{nodes} = {};
    foreach my $entry (@{ $options{custom}->request_optional(command => 'lsnodecanisterstats') }) {
        next unless (ref $entry eq 'HASH'
            && defined($entry->{stat_name}) && $entry->{stat_name} eq 'cpu_pc');
        my $node = $entry->{node_name};
        next if (!defined($node) || $node eq '');
        my $value = $entry->{stat_current};
        next if (!defined($value) || $value !~ /^-?\d+(?:\.\d+)?$/);
        $self->{nodes}->{$node} = { display => $node, cpu => $value };
    }

    $self->{system} = {};
    my @peaks;

    foreach my $measure (@$MEASURES) {
        my $entry = $stats{ $measure->{stat} };
        next if (!defined($entry));

        my $current = $entry->{stat_current};
        next if (!defined($current) || $current !~ /^-?\d+(?:\.\d+)?$/);

        my $scale = defined($measure->{scale}) ? $measure->{scale} : 1;
        $self->{system}->{ $measure->{key} } = $current * $scale;

        next if (!defined($self->{option_results}->{add_peaks}));
        my $peak = $entry->{stat_peak};
        next if (!defined($peak) || $peak !~ /^-?\d+(?:\.\d+)?$/);
        push @peaks, sprintf(
            '%s peak %s%s at %s',
            $measure->{stat}, $peak, $measure->{unit},
            defined($entry->{stat_peak_time}) ? $entry->{stat_peak_time} : 'unknown'
        );
    }

    if (!keys %{ $self->{system} }) {
        $self->{output}->add_option_msg(
            short_msg => 'No usable counter returned by lssystemstats.'
        );
        $self->{output}->option_exit();
    }

    # Le pic est ce que la moyenne sur cinq minutes efface : on le montre en
    # sortie longue plutot que d'en faire une metrique de plus.
    $self->{output}->output_add(long_msg => join("\n", @peaks)) if (@peaks);
}

1;

__END__

=head1 MODE

Check the array performance: latency, bandwidth, IOPS and processor load.

C<lssystemstats> returns counters sampled every five minutes. The current value
becomes the metric; C<--add-peaks> adds the peak and its timestamp to the long
output, because on a five-minute average the peak is what the mean erases.

Only latency ships with thresholds. It is the one indicator with a physical
norm: on all-flash, a few milliseconds is normal and a few tens is not,
whichever array you look at. IOPS, bandwidth and CPU have no good absolute
value — they are set against what you observe, so no default is shipped.

IBM Storage Insights Pro keeps a year of history and dozens of metrics: fine
metrology lives there. This mode exists for the B<alert>, which has to be raised
in Centreon because Centreon is what talks to ServiceNow.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=performance --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure \
        --warning-latency=10 --critical-latency=20

=over 8

=item B<--add-peaks>

Add each counter's peak value and peak time to the long output.

=item B<--warning-latency> B<--critical-latency>

Thresholds on the overall volume latency, in milliseconds. Suggested starting
point on these all-flash systems: 10 and 20. Measured idle values sit around
0.3 ms, so anything in that range is already an order of magnitude off.

=item B<--warning-read-latency> B<--critical-read-latency> B<--warning-write-latency> B<--critical-write-latency>

Same, split by direction. Writes are normally slower than reads — around 0.5 ms
against 0.2 on these arrays — so a single threshold on both hides a write
problem.

=item B<--warning-backend-latency> B<--critical-backend-latency> B<--warning-drive-latency> B<--critical-drive-latency>

Latency of the mdisks and of the drives. Compare with the volume latency: a
system slow at the front but fast at the back points at the cache or the
fabric, not at the disks.

=item B<--warning-iops> B<--critical-iops> B<--warning-bandwidth> B<--critical-bandwidth>

Thresholds on volume IOPS and throughput. Throughput is in bytes per second —
the array reports MB/s and the mode converts.

=item B<--warning-cpu> B<--critical-cpu> B<--warning-compression-cpu> B<--critical-compression-cpu>

Thresholds on the processor load, overall and for compression.

=item B<--warning-node-cpu> B<--critical-node-cpu>

Thresholds on the B<per-canister> CPU load. Storage Virtualize has no load
average; on an active/active pair the telling figure is the imbalance — one
canister carrying everything while the other idles — which the global average
hides. The C<node-cpu> label is chosen so the Cpu service's
C<--filter-counters=cpu> picks these counters up without touching any Centreon
template.

=item B<--warning-write-cache> B<--critical-write-cache> B<--warning-total-cache> B<--critical-total-cache>

Thresholds on cache occupancy. A write cache that stays full is a sign the
backend cannot absorb what the hosts send.

=item B<--warning-fc-iops> B<--critical-fc-iops> B<--warning-fc-bandwidth> B<--critical-fc-bandwidth>

Thresholds on the Fibre Channel load, all ports together.

=back

=cut
