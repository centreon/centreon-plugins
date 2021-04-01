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

package apps::pacemaker::local::mode::clustat;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use XML::Simple;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my %map_node_state = (
    0 => 'down',
    1 => 'up',
    2 => 'clean'
);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s'", $self->{result_values}->{state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok' },
        { name => 'groups', type => 1, cb_prefix_output => 'prefix_group_output', message_multiple => 'All groups/resources are ok' }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node', type => 2, critical_default => '%{state} !~ /up|clean/', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];

    $self->{maps_counters}->{groups} = [
        { label => 'group', type => 2, critical_default => '%{state} !~ /starting|started/', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node: '" . $options{instance_value}->{display} . "' ";
}

sub prefix_group_output {
    my ($self, %options) = @_;

    return "Resource group: '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-node:s'    => { name => 'filter_node' },
        'filter-groups:s'  => { name => 'filter_groups' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'clustat',
        command_path => '/usr/sbin',
        command_options => '-x 2>&1'
    );

    my $clustat_hash = XMLin($stdout);

    foreach my $node (keys %{$clustat_hash->{nodes}->{node}}) {
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $node !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $node . "': no matching filter.", debug => 1);
            next;
        }

        $self->{nodes}->{$node} = {
            display => $node,
            state => $map_node_state{$clustat_hash->{nodes}->{node}->{$node}->{state}}
        };
    }

    foreach my $group_name (keys %{$clustat_hash->{groups}->{group}}) {
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $group_name !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $group_name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{groups}->{$group_name} = {
            display => $group_name,
            state => $clustat_hash->{groups}->{group}->{$group_name}->{state_str}
        };
    }

}

1;

__END__

=head1 MODE

Check Cluster Resource Manager (need 'clustat' command).
Should be executed on a cluster node.

Command used: /usr/sbin/clustat -x 2>&1

=over 8

=item B<--warning-*>

Can be ('group','node')
Warning threshold for status.

=item B<--critical-*>

Can be ('group','node')
Critical threshold for status. (Default: --critical-node '%{state} !~ /up|clean/' --critical-group '%{state} !~ /started|starting/')

=back

=cut
