#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::riverbed::steelhead::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_connection_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'totalConnections' } ],
                output_template => 'total %s',
                perfdatas => [
                    { label => 'total', value => 'totalConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'established', set => {
                key_values => [ { name => 'establishedConnections' } ],
                output_template => 'established %s',
                perfdatas => [
                    { label => 'established', value => 'establishedConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active', set => {
                key_values => [ { name => 'activeConnections' } ],
                output_template => 'active %s',
                perfdatas => [
                    { label => 'active', value => 'activeConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'optimized', set => {
                key_values => [ { name => 'optimizedConnections' } ],
                output_template => 'optimized %s',
                perfdatas => [
                    { label => 'optimized', value => 'optimizedConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'passthrough', set => {
                key_values => [ { name => 'passthroughConnections' } ],
                output_template => 'passthrough %s',
                perfdatas => [
                    { label => 'passthrough', value => 'passthroughConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
         { label => 'half-opened', set => {
                key_values => [ { name => 'halfOpenedConnections' } ],
                output_template => 'half opened %s',
                perfdatas => [
                    { label => 'half_opened', value => 'halfOpenedConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
         { label => 'half-closed', set => {
                key_values => [ { name => 'halfClosedConnections' } ],
                output_template => 'half closed %s',
                perfdatas => [
                    { label => 'half_closed', value => 'halfClosedConnections_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_connection_output {
    my ($self, %options) = @_;
    
    return "Connections: ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # STEELHEAD-MIB
    my $oids = {
        optimizedConnections => '.1.3.6.1.4.1.17163.1.1.5.2.1.0',
        passthroughConnections => '.1.3.6.1.4.1.17163.1.1.5.2.2.0',
        halfOpenedConnections => '.1.3.6.1.4.1.17163.1.1.5.2.3.0',
        halfClosedConnections => '.1.3.6.1.4.1.17163.1.1.5.2.4.0',
        establishedConnections => '.1.3.6.1.4.1.17163.1.1.5.2.5.0',
        activeConnections => '.1.3.6.1.4.1.17163.1.1.5.2.6.0',
        totalConnections => '.1.3.6.1.4.1.17163.1.1.5.2.7.0',
    };

    # STEELHEAD-EX-MIB
    my $oids_ex = {
        optimizedConnections => '.1.3.6.1.4.1.17163.1.51.5.2.1.0',
        passthroughConnections => '.1.3.6.1.4.1.17163.1.51.5.2.2.0',
        halfOpenedConnections => '.1.3.6.1.4.1.17163.1.51.5.2.3.0',
        halfClosedConnections => '.1.3.6.1.4.1.17163.1.51.5.2.4.0',
        establishedConnections => '.1.3.6.1.4.1.17163.1.51.5.2.5.0',
        activeConnections => '.1.3.6.1.4.1.17163.1.51.5.2.6.0',
        totalConnections => '.1.3.6.1.4.1.17163.1.51.5.2.7.0',
    };

    my $snmp_result = $options{snmp}->get_leef(oids => [ values %{$oids}, values %{$oids_ex} ], nothing_quit => 1);

    $self->{global} = {};

    if (defined($snmp_result->{$oids->{optimizedConnections}})) {
        foreach (keys %{$oids}) {
            $self->{global}->{$_} = $snmp_result->{$oids->{$_}};
        }
    } else {
        foreach (keys %{$oids_ex}) {
            $self->{global}->{$_} = $snmp_result->{$oids_ex->{$_}};
        }	
    }
}

1;

__END__

=head1 MODE

Current connections: total, established, active, optimized, passthrough,
half opened and half closed ones (STEELHEAD-MIB and STEELHEAD-EX-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(total)$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'established', 'active', 'optimized',
'passthrough', 'half-opened', 'half-closed'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'established', 'active', 'optimized',
'passthrough', 'half-opened', 'half-closed'.

=back

=cut
