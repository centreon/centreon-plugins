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

package apps::ericsson::enm::api::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_fru_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational state: %s, admin state: %s%s',
        $self->{result_values}->{operational_state},
        $self->{result_values}->{administrative_state},
        $self->{result_values}->{availability_status} ne 'null' ? ', availability status: ' . $self->{result_values}->{availability_status}: ''
    );
}

sub custom_celltdd_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational state: %s, admin state: %s%s',
        $self->{result_values}->{operational_state},
        $self->{result_values}->{administrative_state},
        $self->{result_values}->{availability_status} ne 'null' ? ', availability status: ' . $self->{result_values}->{availability_status}: ''
    );
}

sub prefix_fru_output {
    my ($self, %options) = @_;

    return sprintf(
        "field replaceable unit '%s'%s ",
        $options{instance},
        $options{instance_value}->{label} ne '' ?  ' [label: ' . $options{instance_value}->{label} . ']' : ''
    );
}

sub prefix_celltdd_output {
    my ($self, %options) = @_;

    return sprintf(
        "tdd cell '%s'%s ",
        $options{instance},
        $options{instance_value}->{label} ne '' ?  ' [label: ' . $options{instance_value}->{label} . ']' : ''
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'nodes ';
}

sub node_long_output {
    my ($self, %options) = @_;

    return "checking node '" . $options{instance} . "'";
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output', indent_long_output => '    ', message_multiple => 'All nodes are ok',
            group => [
                { name => 'node_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'fru', display_long => 1, cb_prefix_output => 'prefix_fru_output', message_multiple => 'All field replaceable units are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'celltdd', display_long => 1, cb_prefix_output => 'prefix_celltdd_output',  message_multiple => 'All tdd cells are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'nodes-total', nlabel => 'nodes.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{node_global} = [
        { label => 'node-sync-status', type => 2, critical_default => '%{sync_status} =~ /unsynchronized/i', set => {
                key_values => [ { name => 'sync_status' }, { name => 'node_id' } ],
                output_template => 'synchronization status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{fru} = [
        { label => 'fru-status',  type => 2, set => {
                key_values => [
                    { name => 'node_id' }, { name => 'fru_id' }, { name => 'label' },
                    { name => 'administrative_state' }, { name => 'availability_status' },
                    { name => 'operational_state' }
                ],
                closure_custom_output => $self->can('custom_fru_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{celltdd} = [
        { label => 'cell-tdd-status',  type => 2, set => {
                key_values => [
                    { name => 'node_id' }, { name => 'cell_tdd_id' }, { name => 'label' },
                    { name => 'administrative_state' }, { name => 'availability_status' },
                    { name => 'operational_state' }
                ],
                closure_custom_output => $self->can('custom_celltdd_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-node-id:s'      => { name => 'filter_node_id' },
        'exclude-node-id:s'     => { name => 'exclude_node_id' },
        'filter-fru-id:s'       => { name => 'filter_fru_id' },
        'exclude-fru-id:s'      => { name => 'exclude_fru_id' },
        'filter-cell-tdd-id:s'  => { name => 'filter_cell_tdd_id' },
        'exclude-cell-tdd-id:s' => { name => 'exclude_cell_tdd_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $nodes = $options{custom}->get_nodeSyncState();
    
    $self->{global} = { total => 0 };
    $self->{nodes} = {};
    foreach my $node (@$nodes) {
        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node->{NodeId} !~ /$self->{option_results}->{filter_node_id}/);
        next if (defined($self->{option_results}->{exclude_node_id}) && $self->{option_results}->{exclude_node_id} ne '' &&
            $node->{NodeId} =~ /$self->{option_results}->{exclude_node_id}/);

        $self->{global}->{total}++;
        $self->{nodes}->{ $node->{NodeId} } = {
            node_global => { node_id => $node->{NodeId}, sync_status => lc($node->{syncStatus}) },
            fru => {},
            celltdd => {}
        };
    }

    my $frus = $options{custom}->get_fruState();
    foreach my $fru (@$frus) {
        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $fru->{NodeId} !~ /$self->{option_results}->{filter_node_id}/);
        next if (defined($self->{option_results}->{exclude_node_id}) && $self->{option_results}->{exclude_node_id} ne '' &&
            $fru->{NodeId} =~ /$self->{option_results}->{exclude_node_id}/);
        next if (defined($self->{option_results}->{filter_fru_id}) && $self->{option_results}->{filter_fru_id} ne '' &&
            $fru->{FieldReplaceableUnitId} !~ /$self->{option_results}->{filter_fru_id}/);
        next if (defined($self->{option_results}->{exclude_fru_id}) && $self->{option_results}->{exclude_fru_id} ne '' &&
            $fru->{FieldReplaceableUnitId} =~ /$self->{option_results}->{exclude_fru_id}/);

        $self->{nodes}->{ $fru->{NodeId} }->{fru}->{ $fru->{FieldReplaceableUnitId} } = {
            node_id => $fru->{NodeId},
            fru_id => $fru->{FieldReplaceableUnitId},
            label => defined($fru->{userLabel}) && $fru->{userLabel} ne 'null' ? $fru->{userLabel} : '',
            administrative_state => lc($fru->{administrativeState}),
            availability_status => lc($fru->{availabilityStatus}),
            operational_state => lc($fru->{operationalState})
        };
    }

    my $cells = $options{custom}->get_EUtranCellTDD();
    foreach my $cell (@$cells) {
        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $cell->{NodeId} !~ /$self->{option_results}->{filter_node_id}/);
        next if (defined($self->{option_results}->{exclude_node_id}) && $self->{option_results}->{exclude_node_id} ne '' &&
            $cell->{NodeId} =~ /$self->{option_results}->{exclude_node_id}/);
        next if (defined($self->{option_results}->{filter_cell_tdd_id}) && $self->{option_results}->{filter_cell_tdd_id} ne '' &&
            $cell->{EUtranCellTDDId} !~ /$self->{option_results}->{filter_cell_tdd_id}/);
        next if (defined($self->{option_results}->{exclude_cell_tdd_id}) && $self->{option_results}->{exclude_cell_tdd_id} ne '' &&
            $cell->{EUtranCellTDDId} =~ /$self->{option_results}->{exclude_cell_tdd_id}/);

        $self->{nodes}->{ $cell->{NodeId} }->{celltdd}->{ $cell->{EUtranCellTDDId} } = {
            node_id => $cell->{NodeId},
            cell_tdd_id => $cell->{EUtranCellTDDId},
            label => defined($cell->{userLabel}) && $cell->{userLabel} ne 'null' ? $cell->{userLabel} : '',
            administrative_state => lc($cell->{administrativeState}),
            availability_status => lc($cell->{availabilityStatus}),
            operational_state => lc($cell->{operationalState})
        };
    }
}

1;

__END__

=head1 MODE

Check nodes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total'

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--filter-fru-id>

Filter field replaceable units by ID (can be a regexp).

=item B<--filter-cell-tdd-id>

Filter tdd cells by ID (can be a regexp).

=item B<--unknown-node-sync-status>

Set unknown threshold for synchronization status.
You can use the following variables: %{node_id}, %{sync_status}

=item B<--warning-node-sync-status>

Set warning threshold for synchronization status.
You can use the following variables: %{node_id}, %{sync_status}

=item B<--critical-node-sync-status>

Set critical threshold for synchronization status (default: '%{sync_status} =~ /unsynchronized/i').
You can use the following variables: %{node_id}, %{sync_status}

=item B<--unknown-fru-status>

Set unknown threshold for field replaceable unit status.
You can use the following variables: %{node_id}, %{fru_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--warning-fru-status>

Set warning threshold for field replaceable unit status.
You can use the following variables: %{node_id}, %{fru_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--critical-fru-status>

Set critical threshold for field replaceable unit status.
You can use the following variables: %{node_id}, %{fru_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--unknown-cell-tdd-status>

Set unknown threshold for cell tdd status.
You can use the following variables: %{node_id}, %{cell_tdd_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--warning-cell-tdd-status>

Set warning threshold for cell tdd status.
You can use the following variables: %{node_id}, %{cell_tdd_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--critical-cell-tdd-status>

Set critical threshold for cell tdd status.
You can use the following variables: %{node_id}, %{cell_tdd_id}, %{label}, %{administrative_state}, %{availability_status}, %{operational_state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'nodes-total'.

=back

=cut
