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

package cloud::outscale::mode::vpnconnections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub vpn_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking vpn connection '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return sprintf(
        "vpn connection '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of vpn connections ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'connections', type => 3, cb_prefix_output => 'prefix_vpn_output', cb_long_output => 'vpn_long_output', indent_long_output => '    ', message_multiple => 'All vpn connections are ok',
            group => [
                { name => 'status', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vpn-connections-detected', display_ok => 0, nlabel => 'vpn_connections.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vpn-connections-available', display_ok => 0, nlabel => 'vpn_connections.available.count', set => {
                key_values => [ { name => 'available' } ],
                output_template => 'available: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vpn-connections-pending', display_ok => 0, nlabel => 'vpn_connections.pending.count', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'pending: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vpn-connections-deleting', display_ok => 0, nlabel => 'vpn_connections.deleting.count', set => {
                key_values => [ { name => 'deleting' } ],
                output_template => 'deleting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vpn-connections-deleted', display_ok => 0, nlabel => 'vpn_connections.deleted.count', set => {
                key_values => [ { name => 'deleted' } ],
                output_template => 'deleted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'vpn-connection-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'vpnName' } ],
                output_template => 'state: %s',
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
        'filter-name:s'  => { name => 'filter_name' },
        'vpn-tag-name:s' => { name => 'vpn_tag_name', default => 'name' }
    });

    return $self;
}

sub get_vpn_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{vpn_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $connections = $options{custom}->read_vpn_connections();

    $self->{global} = { detected => 0, available => 0, pending => 0, deleting => 0, deleted => 0 };
    $self->{connections} = {};

    foreach my $connection (@$connections) {
        my $name = $self->get_vpn_name(tags => $connection->{Tags}, id => $connection->{VpnConnectionId});

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{connections}->{$name} = {
            name => $name,
            status => {
                vpnName => $name,
                state => lc($connection->{State})
            }
        };

        $self->{global}->{ lc($connection->{State}) }++
            if (defined($self->{global}->{ lc($connection->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check vpn connections.

=over 8

=item B<--filter-name>

Filter virtual connections by name.

=item B<--vpn-tag-name>

Vpn connection tag to be used for the name (default: 'name').

=item B<--unknown-vpn-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{vpnName}

=item B<--warning-vpn-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vpnName}

=item B<--critical-vpn-connection-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{vpnName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'vpn-connections-detected', 'vpn-connections-available', 'vpn-connections-pending',
'vpn-connections-deleting', 'vpn-connections-deleted'.

=back

=cut
