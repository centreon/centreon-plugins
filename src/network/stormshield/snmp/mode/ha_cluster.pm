# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::ha_cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'dead-nodes',
            nlabel => 'cluster.dead-nodes.count',
            type => COUNTER_KIND_METRIC,
            warning_default => '50',
            critical_default => '100',
            set => {
                key_values => [ { name => 'dead_pct' }, { name => 'nb_nodes' }, { name => 'dead_nodes' } ],
                output_template => 'Dead Nodes: %{dead_nodes}/%{nb_nodes} (%{dead_pct}%%)',
                perfdatas => [
                    { label => 'ha.dead_nodes.count', value => 'dead_nodes', template => '%s', min => 0, max => 'nb_nodes', threshold_total => 'nb_nodes', cast_int => 1 }
                ]
            }
        },
        {
            label => 'faulty-links',
            nlabel => 'cluster.faulty-links.count',
            type => COUNTER_KIND_METRIC,
            warning_default => '50',
            critical_default => '100',
            set => {
                key_values => [ { name => 'faulty_pct' }, { name => 'nb_links' }, { name => 'faulty_links' } ],
                output_template => 'Faulty Links: %{faulty_links}/%{nb_links} (%{faulty_pct}%%)',
                perfdatas => [
                    { label => 'ha.faulty_links.count', value => 'faulty_links', template => '%s', min => 0, max => 'nb_links', threshold_total => 'nb_links', cast_int => 1 }
                ]
            }
        },
        {
            label => 'active-firewall',
            nlabel => 'cluster.active-firewalls.count',
            type => COUNTER_KIND_METRIC,
            critical_default => '1:1',
            set => {
                key_values => [ { name => 'nb_active' } ],
                output_template => 'Active Firewalls: %{nb_active}/2',
                perfdatas => [
                    { label => 'ha.active_firewalls.count', value => 'nb_active', template => '%s', min => 0, max => 2, cast_int => 1 }
                ]
            }
        },
        {
            label => 'sync-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{sync_status} eq "False"',
            set => {
                key_values => [ { name => 'sync_status' } ],
                output_template => 'Configuration Synced: %{sync_status}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

my $oid_snsNode            = '.1.3.6.1.4.1.11256.1.11.7.1';
my $oid_snsNbNode          = '.1.3.6.1.4.1.11256.1.11.1.0';
my $oid_snsNbDeadNode      = '.1.3.6.1.4.1.11256.1.11.2.0';
my $oid_snsNbActiveNode    = '.1.3.6.1.4.1.11256.1.11.3.0';
my $oid_snsNbHALinks       = '.1.3.6.1.4.1.11256.1.11.5.0';
my $oid_snsNbFaultyHALinks = '.1.3.6.1.4.1.11256.1.11.6.0';
my $oid_snsHASyncStatus    = '.1.3.6.1.4.1.11256.1.11.8.0';

my %mapping = (
    snsNodeIndex      => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.1' },
    snsFwSerial       => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.2' },
    snsOnline         => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.3' },
    snsModel          => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.4' },
    snsVersion        => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.5' },
    snsHALicence      => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.6' },
    snsHAQuality      => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.7' },
    snsHAPriority     => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.8' },
    snsHAStatusForced => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.9' },
    snsHAActive       => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.10' },
);

my %map_online = ( 2 => 'False', 1 => 'True' );
my %map_status = ( 0 => 'False', 1 => 'True' );
my %map_act_pass = ( 2 => 'Passive', 1 => 'Active' );
my %map_sync = ( 0 => 'False', 1 => 'True' );

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result_scalar = $options{snmp}->get_leef(
        oids => [
            $oid_snsNbNode,
            $oid_snsNbDeadNode,
            $oid_snsNbActiveNode,
            $oid_snsNbHALinks,
            $oid_snsNbFaultyHALinks,
            $oid_snsHASyncStatus,
        ],
        nothing_quit => 0
    );

    my $nb_nodes       = $snmp_result_scalar->{$oid_snsNbNode}          // 0;
    my $dead_nodes     = $snmp_result_scalar->{$oid_snsNbDeadNode}      // 0;
    my $nb_active      = $snmp_result_scalar->{$oid_snsNbActiveNode}    // 0;
    my $nb_links       = $snmp_result_scalar->{$oid_snsNbHALinks}       // 0;
    my $faulty_links   = $snmp_result_scalar->{$oid_snsNbFaultyHALinks} // 0;
    my $sync_raw       = $snmp_result_scalar->{$oid_snsHASyncStatus}    // -1;

    $self->{output}->option_exit(severity  => 'UNKNOWN', short_msg => 'No HA cluster detected')
        unless $nb_nodes;

    my $dead_pct   = ($nb_nodes > 0) ? int(($dead_nodes / $nb_nodes) * 100) : 0;
    my $faulty_pct = ($nb_links > 0) ? int(($faulty_links / $nb_links) * 100) : 0;
    my $sync_str   = $map_sync{$sync_raw} // 'UNKNOWN';

    $self->{global} = {
        dead_nodes => $dead_nodes,
        nb_nodes => $nb_nodes,
        dead_pct => $dead_pct,
        faulty_links => $faulty_links,
        nb_links => $nb_links,
        faulty_pct => $faulty_pct,
        nb_active => $nb_active,
        sync_status => $sync_str,
    };

    my $snmp_result_table = $options{snmp}->get_table(
        oid => $oid_snsNode,
        nothing_quit => 1
    );

    my %nodes;
    foreach my $oid (sort keys %{$snmp_result_table}) {
        foreach my $field (keys %mapping) {
            my $col_oid = $mapping{$field}->{oid};
            next if !defined($col_oid);
            if ($oid =~ /^\Q$col_oid\E\.(\d+)$/) {
                my $idx = $1;
                $nodes{$idx}->{$field} = $snmp_result_table->{$oid};
            }
        }
    }

    my $cluster_desc = "---- Cluster Description ----\n";

    foreach my $idx (sort { $a <=> $b } keys %nodes) {
        my $n = $nodes{$idx};

        my $serial = $n->{snsFwSerial} // 'N/A';
        my $model = $n->{snsModel} // 'N/A';
        my $version = $n->{snsVersion} // 'N/A';
        my $status_f = $map_status{ $n->{snsHAStatusForced} // 0 } // 'UNKNOWN';
        my $act_pass = $map_act_pass{ $n->{snsHAActive} // 0 } // 'UNKNOWN';
        my $online = $map_online{ $n->{snsOnline} // 0 } // 'UNKNOWN';
        my $licence = $n->{snsHALicence} // 'N/A';
        my $quality = $n->{snsHAQuality} // 'N/A';
        my $priority = $n->{snsHAPriority} // 'N/A';

        $cluster_desc .= sprintf(
            "Serial: %s\nModel: %s\nVersion: %s\nStatus Forced: %s\nActive/Passive: %s\nOnline: %s\nLicense: %s\nQuality: %s\nPriority: %s\n%s\n",
            $serial,
            $model,
            $version,
            $status_f,
            $act_pass,
            $online,
            $licence,
            $quality,
            $priority,
            '-' x 25
        );
    }

    $self->{output}->output_add(long_msg => $cluster_desc);
}

1;

__END__

=head1 MODE

Check Stormshield HA cluster global status.

=over 8

=item B<--warning-active-firewall>

Threshold.

=item B<--critical-active-firewall>

Threshold. Default: C<1:1> since there must be only one active firewall per cluster.

=item B<--warning-dead-nodes>

Threshold in percentage of the total number of nodes. Default: 50.

=item B<--critical-dead-nodes>

Threshold in percentage of the total number of nodes. Default: 100.

=item B<--warning-faulty-links>

Threshold in percentage of the total number of links. Default: 50.

=item B<--critical-faulty-links>

Threshold in percentage of the total number of links. Default: 100.

=item B<--warning-sync-status>

Define the conditions to match for the status to be WARNING (default: C<%{sync_status} eq "False">).
You can use the following variables: %{sync_status}.

=item B<--critical-sync-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{sync_status}.

=back

=cut
