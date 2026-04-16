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

package network::hp::athonet::nodeexporter::api::mode::dra;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(is_excluded);

sub prefix_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        "diameter stack '%s' origin host '%s' ",
        $options{instance_value}->{stack},
        $options{instance_value}->{originHost}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of diameter connections ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'connections', type => 1, cb_prefix_output => 'prefix_connection_output', message_multiple => 'All diameter connections are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'diameter-connections-detected', display_ok => 0, nlabel => 'diameter.connections.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'diameter-connections-up', display_ok => 0, nlabel => 'diameter.connections.up.count', display_ok => 0, set => {
                key_values => [ { name => 'up' }, { name => 'detected' } ],
                output_template => 'up: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'diameter-connections-down', display_ok => 0, nlabel => 'diameter.connections.down.count', display_ok => 0, set => {
                key_values => [ { name => 'down' }, { name => 'detected' } ],
                output_template => 'down: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connections} = [
        { label => 'diameter-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'originHost' }, { name => 'stack' } ],
                output_template => 'connection status: %s',
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
        'filter-origin-host:s' => { name => 'filter_origin_host' },
        'filter-stack:s'       => { name => 'filter_stack' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $connections = $options{custom}->query(queries => ['diameter_peer_status']);

    my $map_status = { 1 => 'up', 0 => 'down' };

    my $id = 0;
    $self->{global} = { detected => 0, up => 0, down => 0 };
    $self->{connections} = {};
    foreach my $connection (@$connections) {
        next if is_excluded($connection->{metric}->{orig_host}, $self->{option_results}->{filter_origin_host});
        next if is_excluded($connection->{metric}->{stack}, $self->{option_results}->{filter_stack});
 
        $self->{global}->{detected}++;
        $self->{global}->{ $map_status->{ $connection->{value}->[1] } }++;

        $self->{connections}->{$id} = {
            originHost => $connection->{metric}->{orig_host},
            stack => $connection->{metric}->{stack},
            status => $map_status->{ $connection->{value}->[1] }
        };
        
        $id++;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['origin_host', 'stack', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $connections = $options{custom}->query(queries => ['diameter_peer_status']);

    my $map_status = { 1 => 'up', 0 => 'down' };
    foreach my $connection (@$connections) {
        $self->{output}->add_disco_entry(
            originHost => $connection->{metric}->{orig_host},
            stack => $connection->{metric}->{stack},
            status => $map_status->{ $connection->{value}->[1] }
        );
    }
}

1;

__END__

=head1 MODE

Check diameter routing agent.

=over 8

=item B<--filter-origin-host>

Filter diameter peers by origin host.

=item B<--filter-stack>

Filter diameter peers by stack.

=item B<--unknown-diameter-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>

=item B<--warning-diameter-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>

=item B<--critical-diameter-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>

=item B<--warning-diameter-connections-detected>

Thresholds.

=item B<--critical-diameter-connections-detected>

Thresholds.

=item B<--warning-diameter-connections-up>

Thresholds.

=item B<--critical-diameter-connections-up>

Thresholds.

=item B<--warning-diameter-connections-down>

Thresholds.

=item B<--critical-diameter-connections-down>

Thresholds.

=back

=cut
