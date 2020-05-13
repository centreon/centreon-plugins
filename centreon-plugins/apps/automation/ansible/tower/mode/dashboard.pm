#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::automation::ansible::tower::mode::dashboard;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output'},
    ];

    $self->{maps_counters}->{global} = [
        { label => 'hosts-total', nlabel => 'hosts.total.count', set => {
                key_values => [ { name => 'hosts_total' } ],
                output_template => 'Hosts Total: %d',
                perfdatas => [
                    { value => 'hosts_total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'hosts-failed', nlabel => 'hosts.failed.count', set => {
                key_values => [ { name => 'hosts_failed' },{ name => 'hosts_total' } ],
                output_template => 'Hosts Failed: %d',
                perfdatas => [
                    { value => 'hosts_failed', template => '%d', min => 0,
                      max => 'hosts_total' },
                ],
            }
        },
        { label => 'inventories-total', nlabel => 'inventories.total.count', set => {
                key_values => [ { name => 'inventories_total' } ],
                output_template => 'Inventories Total: %d',
                perfdatas => [
                    { value => 'inventories_total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'inventories-sync-failed', nlabel => 'inventories.sync.failed.count', set => {
                key_values => [ { name => 'inventories_sync_failed' }, { name => 'inventories_total' } ],
                output_template => 'Inventories Sync Failed: %d',
                perfdatas => [
                    { value => 'inventories_sync_failed', template => '%d', min => 0,
                      max => 'inventories_total' },
                ],
            }
        },
        { label => 'projects-total', nlabel => 'projects.total.count', set => {
                key_values => [ { name => 'projects_total' } ],
                output_template => 'Projects Total: %d',
                perfdatas => [
                    { value => 'projects_total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'projects-sync-failed', nlabel => 'projects.sync.failed.count', set => {
                key_values => [ { name => 'projects_sync_failed' }, { name => 'projects_total' } ],
                output_template => 'Projects Sync Failed: %d',
                perfdatas => [
                    { value => 'projects_sync_failed', template => '%d', min => 0,
                      max => 'projects_total' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{global} = {
        hosts_total => 0, hosts_failed => 0,
        inventories_total => 0, inventories_sync_failed => 0,
        projects_total => 0, projects_sync_failed => 0
    };

    my $hosts = $options{custom}->tower_list_hosts();
    $self->{global}->{hosts_total} = $hosts->{count};
    foreach my $host (@{$hosts->{results}}) {
        $self->{global}->{hosts_failed}++ if ($host->{has_active_failures});
    }

    my $inventories = $options{custom}->tower_list_inventories();
    $self->{global}->{inventories_total} = $inventories->{count};
    foreach my $inventory (@{$inventories->{results}}) {
        $self->{global}->{inventories_sync_failed}++ if ($inventory->{inventory_sources_with_failures} > 0);
    }

    my $projects = $options{custom}->tower_list_projects();
    $self->{global}->{projects_total} = $projects->{count};
    foreach my $project (@{$projects->{results}}) {
        $self->{global}->{projects_sync_failed}++ if ($project->{status} =~ /failed|canceled/);
    }
}

1;

__END__

=head1 MODE

Check several counters available through Tower dashboard.

=over 8

=item B<--warning-hosts-*-count>

Threshold warning.
Can be: 'total', 'failed'.

=item B<--critical-hosts-*-count>

Threshold critical.
Can be: 'total', 'failed'.

=item B<--warning-inventories-*-count>

Threshold warning.
Can be: 'total', 'sync-failed'.

=item B<--critical-inventories-*-count>

Threshold critical.
Can be: 'total', 'sync-failed'.

=item B<--warning-projects-*-count>

Threshold warning.
Can be: 'total', 'sync-failed'.

=item B<--critical-projects-*-count>

Threshold critical.
Can be: 'total', 'sync-failed'.

=back

=cut
