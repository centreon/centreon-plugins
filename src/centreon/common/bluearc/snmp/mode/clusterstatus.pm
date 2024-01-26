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

package centreon::common::bluearc::snmp::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state : ' . $self->{result_values}->{state};
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok' }
    ];

    $self->{maps_counters}->{node} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{state} =~ /unknown/',
            critical_default => '%{state} =~ /offline/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my %map_vnode_status = (
    1 => 'unknown',
    2 => 'onLine',
    3 => 'offLine'
);

my $mapping = {
    clusterVNodeName    => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.2.5.11.1.2' },
    clusterVNodeStatus  => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.2.5.11.1.4', map => \%map_vnode_status }
};
my $oid_clusterVNodeEntry = '.1.3.6.1.4.1.11096.6.1.1.1.2.5.11.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{node} = {};
    $self->{results} = $options{snmp}->get_table(oid => $oid_clusterVNodeEntry, nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{clusterVNodeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{clusterVNodeName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{clusterVNodeName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{node}->{$instance} = {
            display => $result->{clusterVNodeName},
            state => $result->{clusterVNodeStatus}
        };
    }

    if (scalar(keys %{$self->{node}}) <= 0) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'No node(s) found'
        );
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{state} =~ /unknown/').
You can use the following variables: %{state}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: -).
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /offline/i').
You can use the following variables: %{state}, %{display}

=back

=cut
