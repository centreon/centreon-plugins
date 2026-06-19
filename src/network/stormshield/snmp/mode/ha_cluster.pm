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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);


sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Configuration Synced: %s",
        $self->{result_values}->{sync_status}
    );
}

sub custom_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "Dead Nodes: %s/%s (%s%%)",
        $self->{result_values}->{dead_nodes},
        $self->{result_values}->{nb_nodes},
        $self->{result_values}->{dead_pct},
    );
}

sub custom_link_output {
    my ($self, %options) = @_;

    return sprintf(
        "Faulty Links: %s/%s (%s%%)",
        $self->{result_values}->{faulty_links},
        $self->{result_values}->{nb_links},
        $self->{result_values}->{faulty_pct},
    );
}

sub custom_active_output {
    my ($self, %options) = @_;

    return sprintf(
        "Active Firewalls: %s/2",
        $self->{result_values}->{nb_active},
    );
}


sub custom_node_perfdata {
    my ($self, %options) = @_;
    my $nb = $self->{result_values}->{nb_nodes};
    my $warn = defined($nb) ? int($nb * 0.5) : undef;
    my $crit = defined($nb) ? $nb : undef;
    
    $self->{output}->perfdata_add(
        label => 'ha.dead_nodes.count',
        value => $self->{result_values}->{dead_nodes},
        warning => $warn,
        critical => $crit,
        min => 0,
        max => $nb,
    )
}

sub custom_link_perfdata {
    my ($self, %options) = @_;
    my $nb = $self->{result_values}->{nb_links};
    my $warn = defined($nb) ? int($nb * 0.5) : undef;
    my $crit = defined($nb) ? $nb : undef;
    
    $self->{output}->perfdata_add(
        label => 'ha.faulty_links.count',
        value => $self->{result_values}->{faulty_links},
        warning => $warn,
        critical => $crit,
        min => 0,
        max => $nb,
    )
}

sub custom_node_threshold {
    my ($self, %options) = @_;
    my $nb = $self->{result_values}->{nb_nodes};
    my $dead = $self->{result_values}->{dead_nodes};
    return 'OK' if !defined($nb) || $nb == 0;
    return 'WARNING' if $dead >= int($nb*0.5);
    return 'CRITICAL' if $dead >= $nb;
    return 'OK';
}


sub custom_link_threshold {
    my ($self, %options) = @_;
    my $nb = $self->{result_values}->{nb_links};
    my $dead = $self->{result_values}->{faulty_links};
    return 'OK' if !defined($nb) || $nb == 0;
    return 'WARNING' if $dead >= int($nb*0.5);
    return 'CRITICAL' if $dead >= $nb;
    return 'OK';
}

sub custom_active_threshold {
    my ($self, %options) = @_;
    my $nb = $self->{result_values}->{nb_active};
    return 'OK' if !defined($nb) || $nb == 1;
    return 'CRITICAL' if $nb == 2 || $nb == 0;
    return 'UNKNOWN';
}

sub custom_sync_threshold {
    my ($self, %options) = @_;
    return 'WARNING' if $self->{result_values}->{sync_status} eq 'False';
    return 'OK';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'dead-nodes',
            set => {
                key_values => [ { name => 'dead_nodes' }, { name => 'nb_nodes' }, { name => 'dead_pct' } ],
                closure_custom_output => $self->can('custom_node_output'),
                closure_custom_perfdata => $self->can('custom_node_perfdata'),
                closure_custom_threshold_check => $self->can('custom_node_threshold'),
            }
        },
        {
            label => 'faulty-links',
            set => {
                key_values => [ { name => 'faulty_links' }, { name => 'nb_links' }, { name => 'faulty_pct' } ],
                closure_custom_output => $self->can('custom_link_output'),
                closure_custom_perfdata => $self->can('custom_link_perfdata'),
                closure_custom_threshold_check => $self->can('custom_link_threshold'),
            }
        },
        {
            label => 'active-firewall',
            set => {
                key_values => [ { name => 'nb_active' } ],
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),
            }
        },
        {
            label => 'sync-status',
            set => {
                key_values => [ { name => 'sync_status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_sync_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{output}->{option_results}->{verbose} = 1;

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
    snsNodeIndex        => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.1' },
    snsFwSerial         => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.2' },
    snsOnline           => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.3' },
    snsOnline           => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.4' },
    snsVersion          => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.5' },
    snsHALicence        => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.6' },
    snsHAQuality        => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.7' },
    snsHAPriority       => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.8' },
    snsHAStatusForced   => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.9' },
    snsHAActive         => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.10' },
);

my %map_online = ( 0 => 'False', 1 => 'True' );
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
    
    if (!(defined $nb_nodes && $nb_nodes > 0)) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No HA cluster detected'
        );
        return;
    }

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

    foreach my $idx(sort { $a <=> $b } keys %nodes) {
        my $n = $nodes{$idx}; 
              
        my $serial = $n->{snsFwSerial} // 'N/A';
        my $model = $n->{snsOnline} // 'N/A';
        my $version = $n->{snsVersion} // 'N/A';
        my $status_f = $map_status{$n->{snsHAStatusForced} // 0 } // 'UNKNOWN';
        my $act_pass = $map_act_pass{$n->{snsHAActive} // 0 } // 'UNKNOWN';
        my $online = $map_online{$n->{snsOnline} // 0 } // 'UNKNOWN';
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

=back

=cut