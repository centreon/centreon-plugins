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

package centreon::common::riverbed::steelhead::snmp::mode::connections;

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
                    { label => 'total', value => 'totalConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'established', set => {
                key_values => [ { name => 'establishedConnections' } ],
                output_template => 'established %s',
                perfdatas => [
                    { label => 'established', value => 'establishedConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active', set => {
                key_values => [ { name => 'activeConnections' } ],
                output_template => 'active %s',
                perfdatas => [
                    { label => 'active', value => 'activeConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'optimized', set => {
                key_values => [ { name => 'optimizedConnections' } ],
                output_template => 'optimized %s',
                perfdatas => [
                    { label => 'optimized', value => 'optimizedConnections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'passthrough', set => {
                key_values => [ { name => 'passthroughConnections' } ],
                output_template => 'passthrough %s',
                perfdatas => [
                    { label => 'passthrough', value => 'passthroughConnections', template => '%s', min => 0 },
                ],
            }
        },
         { label => 'half-opened', set => {
                key_values => [ { name => 'halfOpenedConnections' } ],
                output_template => 'half opened %s',
                perfdatas => [
                    { label => 'half_opened', value => 'halfOpenedConnections', template => '%s', min => 0 },
                ],
            }
        },
         { label => 'half-closed', set => {
                key_values => [ { name => 'halfClosedConnections' } ],
                output_template => 'half closed %s',
                perfdatas => [
                    { label => 'half_closed', value => 'halfClosedConnections', template => '%s', min => 0 },
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

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mappings = {
    common    => {
        optimizedConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.1' },
        passthroughConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.2' },
        halfOpenedConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.3' },
        halfClosedConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.4' },
        establishedConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.5' },
        activeConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.6' },
        totalConnections => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.7' },
    },
    ex => {
        optimizedConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.1' },
        passthroughConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.2' },
        halfOpenedConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.3' },
        halfClosedConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.4' },
        establishedConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.5' },
        activeConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.6' },
        totalConnections => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.7' },
    },
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.5.2',
    ex => '.1.3.6.1.4.1.17163.1.51.5.2',
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{common}, start => $mappings->{common}->{optimizedConnections}->{oid}, end => $mappings->{common}->{totalConnections}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{optimizedConnections}->{oid}, end => $mappings->{ex}->{totalConnections}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment},
            results => $results->{$oids->{$equipment}}, instance => 0);
        
        $self->{global} = { %$result };
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
