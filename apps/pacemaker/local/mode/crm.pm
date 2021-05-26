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

package apps::pacemaker::local::mode::crm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_resource_threshold {
    my ($self, %options) = @_;

    my $status = catalog_status_threshold_ng($self, %options);
    if (defined($self->{instance_mode}->{resources_check}->{ $self->{result_values}->{name} }) 
        && $self->{instance_mode}->{resources_check}->{ $self->{result_values}->{name} } ne $self->{result_values}->{node}) {
        return $self->{output}->get_most_critical(status => [ $status, 'warning' ]);
    }

    return $status;
}

sub custom_connection_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection status: %s [error: %s]',
        $self->{result_values}->{connection_status},
        $self->{result_values}->{connection_error}
    );
}

sub custom_quorum_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'quorum status: %s',
        $self->{result_values}->{quorum_status}
    );
}

sub custom_nodes_online_output {
    my ($self, %options) = @_;

    return sprintf(
        'online: %s [%s]',
        $self->{result_values}->{online},
        $self->{result_values}->{online_names}
    );
}

sub custom_nodes_offline_output {
    my ($self, %options) = @_;

    return sprintf(
        'offline: %s [%s]',
        $self->{result_values}->{offline},
        $self->{result_values}->{offline_names}
    );
}

sub custom_nodes_standby_output {
    my ($self, %options) = @_;

    return sprintf(
        'standby: %s [%s]',
        $self->{result_values}->{standby},
        $self->{result_values}->{standby_names}
    );
}

sub custom_resource_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [node: %s] [unmanaged: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{node},
        $self->{result_values}->{is_unmanaged}
    );
}

sub custom_clone_resource_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [masters: %s] [slaves: %s] [unmanaged: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{masters_nodes_name},
        $self->{result_values}->{slaves_nodes_name},
        $self->{result_values}->{is_unmanaged}
    );
}

sub prefix_rsc_output {
    my ($self, %options) = @_;

    return "resource '" . $options{instance_value}->{name} . "' ";
}

sub prefix_clone_rsc_output {
    my ($self, %options) = @_;

    return "clone resource '" . $options{instance_value}->{name} . "' ";
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return 'nodes ';
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return 'checking cluster';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 3, cb_long_output => 'cluster_long_output', indent_long_output => '    ',
            group => [
                { name => 'connection', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'quorum', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'nodes', type => 0, display_short => 0, cb_prefix_output => 'prefix_nodes_output', skipped_code => { -10 => 1 } },
                { name => 'actions', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
            ]
        },
        { name => 'resources', type => 1, display_short => 0, cb_prefix_output => 'prefix_rsc_output', skipped_code => { -10 => 1 } },
        { name => 'clone_resources', type => 1, display_short => 0, cb_prefix_output => 'prefix_clone_rsc_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'connection-status', type => 2, critical_default => '%{connection_status} =~ /failed/i', set => {
                key_values => [ { name => 'connection_status' }, { name => 'connection_error' } ],
                closure_custom_output => $self->can('custom_connection_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{quorum} = [
        { label => 'quorum-status', type => 2, critical_default => '%{quorum_status} =~ /noQuorum/i', set => {
                key_values => [ { name => 'quorum_status' } ],
                closure_custom_output => $self->can('custom_quorum_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'nodes-online', nlabel => 'cluster.nodes.online.count', set => {
                key_values => [ { name => 'online' }, { name => 'online_names' } ],
                closure_custom_output => $self->can('custom_nodes_online_output'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'nodes-offline', nlabel => 'cluster.nodes.offline.count', set => {
                key_values => [ { name => 'offline' }, { name => 'offline_names' } ],
                closure_custom_output => $self->can('custom_nodes_offline_output'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'nodes-standby', nlabel => 'cluster.nodes.standby.count', set => {
                key_values => [ { name => 'standby' }, { name => 'standby_names' } ],
                closure_custom_output => $self->can('custom_nodes_standby_output'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{actions} = [
        { label => 'cluster-actions-failed', nlabel => 'cluster.actions.failed.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'actions failed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{resources} = [
        { label => 'resource-status', type => 2, critical_default => '%{status} =~ /stopped|failed/i', set => {
                key_values => [ { name => 'status' }, { name => 'is_unmanaged' }, { name => 'node' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_resource_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_resource_threshold')
            }
        },
        { label => 'resource-actions-failed', nlabel => 'resource.actions.failed.count', set => {
                key_values => [ { name => 'failed_actions' } ],
                output_template => 'actions failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'resource-migration-failed', nlabel => 'resource.migration.failed.count', set => {
                key_values => [ { name => 'failed_migration' } ],
                output_template => 'migration failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{clone_resources} = [
        { label => 'clone-resource-status', type => 2, critical_default => '%{status} =~ /failed/i', set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'is_unmanaged' },
                    { name => 'masters_nodes_name' }, { name => 'slaves_nodes_name' }
                ],
                closure_custom_output => $self->can('custom_clone_resource_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'clone-resource-actions-failed', nlabel => 'clone_resource.actions.failed.count', set => {
                key_values => [ { name => 'failed_actions' } ],
                output_template => 'actions failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'clone-resource-migration-failed', nlabel => 'clone_resource.migration.failed.count', set => {
                key_values => [ { name => 'failed_migration' } ],
                output_template => 'migration failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-resource-name:s'   => { name => 'filter_resource_name' },
        'resources:s'              => { name => 'resources' },  # legacy
        'ignore-failed-actions:s@' => { name => 'ignore_failed_actions' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{resources})) {
        foreach (split(/,/, $self->{option_results}->{resources})) {
            my ($rsc_name, $node) = split(/:/, $_);
            if (defined($rsc_name) && $rsc_name ne '' && 
                defined($node) && $node ne '') {
                $self->{resources_check}->{$rsc_name} = $node;
            }
        }
    }
}

sub parse_crm {
    my ($self, %options) = @_;

    $self->{cluster} = {
        global => {
            connection => {
                connection_status => 'ok',
                connection_error => '-',
            },
            quorum => {
                quorum_status => '-'
            },
            nodes => {
                online => 0,
                online_names => '',
                offline => 0,
                offline_names => '',
                standby => 0,
                standby_names => '',
            },
            actions => {
                failed => 0
            }
        }
    };
    $self->{resources} = {};
    $self->{clone_resources} = {};

    my @lines = split /\n/, $options{crm_out};
    my $num_lines = scalar(@lines);
    for (my $i = 0; $i < $num_lines; $i++) {
        if ($lines[$i] =~ /Connection to cluster failed\:(.*)/i ) {
            $self->{cluster}->{global}->{connection}->{connection_status} = 'failed';
            $self->{cluster}->{global}->{connection}->{connection_error} = $1;
        } elsif ($lines[$i] =~ /Current DC:/) {
            $self->{cluster}->{global}->{quorum}->{quorum_status} = 'ok';
            if ($lines[$i] !~ /partition with quorum$/) {
                $self->{cluster}->{global}->{quorum}->{quorum_status} = 'noQuorum';
            }
        } elsif ($lines[$i] =~ /^(offline|online):\s*\[\s*(.*?)\s*\]/i) {
            my @nodes = split(/\s+/, $2);
            $self->{cluster}->{global}->{nodes}->{lc($1)} = scalar(@nodes);
            $self->{cluster}->{global}->{nodes}->{lc($1) . '_names'} = ' ' . join(' ',  @nodes);
        } elsif ($lines[$i] =~ /^node\s+(\S+?):\s*standby/i) {
            $self->{cluster}->{global}->{nodes}->{standby}++;
            $self->{cluster}->{global}->{nodes}->{standby_names} .= ' ' . $1;
        } elsif ($lines[$i] =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Started\s+([0-9a-zA-Z_\-]+)/) {
            my ($name, $node) = ($1, $2);
            if (defined($self->{option_results}->{filter_resource_name}) && $self->{option_results}->{filter_resource_name} ne '' &&
                $name !~ /$self->{option_results}->{filter_resource_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            $self->{resources}->{$name} = { name => $name, failed_actions => 0, failed_migration => 0, status => 'started', node => $node, is_unmanaged => 'no' };
            $self->{resources}->{$name}->{is_unmanaged} = 'yes' if ($lines[$i] =~ /unmanaged/);
            $self->{resources}->{$name}->{status} = 'failed' if ($lines[$i] =~ /FAILED/i);
        } elsif ($lines[$i] =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Stopped/ || $lines[$i] =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+\(\S+\)\s+Stopped/) {
            my $name = $1;
            if (defined($self->{option_results}->{filter_resource_name}) && $self->{option_results}->{filter_resource_name} ne '' &&
                $name !~ /$self->{option_results}->{filter_resource_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            $self->{resources}->{$name} = { name => $name, failed_actions => 0, failed_migration => 0, status => 'stopped', node => '-', is_unmanaged => 'no' };
            $self->{resources}->{$name}->{is_unmanaged} = 'yes' if ($lines[$i] =~ /unmanaged/);
            $self->{resources}->{$name}->{status} = 'failed' if ($lines[$i] =~ /FAILED/i);
        } elsif ($lines[$i] =~ /Master\/Slave.*\[(.*)\]/i) {
            #Master/Slave Set: ms_mysql-master [ms_mysql]
            #    ms_mysql	(ocf::heartbeat:mysql-centreon):	FAILED node-db-passive
            #    Masters: [ node-db-active ]
            #    Stopped: [ node-map-active node-map-passive ]
            
            #Master/Slave Set: ms_mysql-master [ms_mysql]
            #   Masters: [ node-db-active ]
            #   Slaves: [ node-db-passive ]
            #   Stopped: [ node-map-active node-map-passive ]
            
            #Master/Slave Set: ms_mysql-master [ms_mysql]
            #   ms_mysql	(ocf::heartbeat:mysql-centreon):	Master node-db-active (unmanaged)
            #   ms_mysql	(ocf::heartbeat:mysql-centreon):	Slave node-db-passive (unmanaged)
            #   Stopped: [ cps-map-active cps-map-passive ]
            my $name = $1;
            if (defined($self->{option_results}->{filter_resource_name}) && $self->{option_results}->{filter_resource_name} ne '' &&
                $name !~ /$self->{option_results}->{filter_resource_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }

            $self->{clone_resources}->{$name} = {
                name => $name,
                failed_actions => 0,
                failed_migration => 0,
                status => 'ok',
                is_unmanaged => 'no',
                masters_nodes_name => '',
                slaves_nodes => 0,
                slaves_nodes_name => '',
                stopped_nodes => 0,
                stopped_nodes_name => ''
            };
            for (; $i < $num_lines; $i++) {
                if ($lines[$i + 1] =~ /^\s+(masters|slaves|stopped):\s*\[\s*(.*?)\s*\]/i) {
                    my $type = lc($1);
                    my @nodes = split(/\s+/, $2);
                    $self->{clone_resources}->{$name}->{$type . '_nodes'} = scalar(@nodes);
                    $self->{clone_resources}->{$name}->{$type . '_nodes_name'} = join(' ', @nodes);
                } elsif ($lines[$i + 1] =~ /^\s+$name\s+.*unmanaged/) {
                    $self->{clone_resources}->{$name}->{is_unmanaged} = 'yes';
                } elsif ($lines[$i + 1] =~ /^\s+$name\s+.*FAILED/i) {
                    $self->{clone_resources}->{$name}->{status} = 'failed';
                } else {
                    last;
                }
            }
        } elsif ($lines[$i] =~ /^Failed\s+(?:(Resource|Fencing)\s+)?actions:/i) {
            for (; $i < $num_lines; $i++) {
                last if ($lines[$i + 1] !~ /^\*\s+/);
                my $skip = 0;
                foreach (@{$self->{option_results}->{ignore_failed_actions}}) {
                    if ($lines[$i + 1] =~ /$_/) {
                        $skip = 1;
                        last;
                    }
                }
                next if ($skip == 1);

                if ($lines[$i + 1] =~ /^\*\s+(\S+?)_(start|stop|status|monitor|promote|demote)_/) {
                    $self->{clone_resources}->{$1}->{failed_actions}++
                        if (defined($self->{clone_resources}->{$1}));
                    $self->{resources}->{$1}->{failed_actions}++
                        if (defined($self->{resources}->{$1}));
                }

                $self->{cluster}->{global}->{actions}->{failed}++;
            }
        } elsif ($lines[$i] =~ /\s*(\S+?):.*migration.*fail-count=(\d+)/i) {
            $self->{clone_resources}->{$1}->{failed_migration} += $2
                if (defined($self->{clone_resources}->{$1}));
            $self->{resources}->{$1}->{failed_migration} += $2
                if (defined($self->{resources}->{$1}));
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'crm_mon',
        command_path => '/usr/sbin',
        command_options => '-1 -r -f 2>&1'
    );
    $self->parse_crm(crm_out => $stdout);

    $self->{output}->output_add(short_msg => 'Cluster is ok');
}

1;

__END__

=head1 MODE

Check cluster resource manager (need 'crm_mon' command).
Should be executed on a cluster node.

Command used: /usr/sbin/crm_mon -1 -r -f 2>&1

=over 8

=item B<--filter-resource-name>

Filter resource (also clone resource) by name (can be a regexp).

=item B<--warning-connection-status>

Set warning threshold for status.
Can used special variables like: %{connection_status}, %{connection_error}

=item B<--critical-connection-status>

Set critical threshold for status (Default: '%{connection_status} =~ /failed/i').
Can used special variables like: %{connection_status}, %{connection_error}

=item B<--warning-quorum-status>

Set warning threshold for status.
Can used special variables like: %{quorum_status}

=item B<--critical-quorum-status>

Set critical threshold for status (Default: '%{quorum_status} =~ /noQuorum/i').
Can used special variables like: %{quorum_status}

=item B<--warning-resource-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{status}, %{node}, %{is_unmanaged}

=item B<--critical-resource-status>

Set critical threshold for status (Default: '%{status} =~ /stopped|failed/i').
Can used special variables like: %{name}, %{status}, %{node}, %{is_unmanaged}

=item B<--warning-clone-resource-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{status}, %{masters_nodes_name}, %{slaves_nodes_name}, %{is_unmanaged}

=item B<--critical-clone-resource-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{name}, %{status}, %{masters_nodes_name}, %{slaves_nodes_name}, %{is_unmanaged}

=item B<--ignore-failed-actions>

Failed actions errors (that match) are skipped.

=item B<--resources>

If resources not started on the node specified, send a warning message:
(format: <rsc_name>:<node>,<rsc_name>:<node>,...)

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'cluster-actions-failed',
'clone-resource-actions-failed', 'clone-resource-migration-failed',
'nodes-online', 'nodes-offline', 'nodes-standby',
'resource-actions-failed', 'resource-migration-failed'.

=back

=cut
