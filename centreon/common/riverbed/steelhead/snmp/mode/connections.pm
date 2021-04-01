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

package centreon::common::riverbed::steelhead::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_optimized_output {
    my ($self, %options) = @_;

    return sprintf(
        "optimized total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{max_optimized},
        $self->{result_values}->{optimized},
        $self->{result_values}->{prct_optimized},
        $self->{result_values}->{optimized_free},
        $self->{result_values}->{prct_optimized_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_connection_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'connections.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'established', nlabel => 'connections.established.count', set => {
                key_values => [ { name => 'established' } ],
                output_template => 'established %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'active', nlabel => 'connections.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },

        { label => 'optimized', nlabel => 'connections.optimized.count', set => {
                key_values => [ { name => 'optimized' }, { name => 'optimized_free' }, { name => 'prct_optimized' }, { name => 'prct_optimized_free' }, { name => 'max_optimized' } ],
                closure_custom_output => $self->can('custom_optimized_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'max_optimized' }
                ]
            }
        },
        { label => 'optimized-prct', display_ok => 0, nlabel => 'connections.optimized.percentage', set => {
                key_values => [ { name => 'prct_optimized' }, { name => 'optimized_free' }, { name => 'optimized' }, { name => 'prct_optimized_free' }, { name => 'max_optimized' } ],
                closure_custom_output => $self->can('custom_optimized_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'passthrough', nlabel => 'connections.passthrough.count', set => {
                key_values => [ { name => 'passthrough' } ],
                output_template => 'passthrough %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'half-opened', nlabel => 'connections.half_opened.count', set => {
                key_values => [ { name => 'half_opened' } ],
                output_template => 'half opened %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'half-closed', nlabel => 'connections.half_closed.count', set => {
                key_values => [ { name => 'half_closed' } ],
                output_template => 'half closed %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_connection_output {
    my ($self, %options) = @_;
    
    return 'Connections: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mappings = {
    common    => {
        max_optimized => { oid => '.1.3.6.1.4.1.17163.1.1.2.13.1' }, # shMaxConnections
        optimized     => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.1' }, # optimizedConnections
        passthrough   => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.2' }, # passthroughConnections
        half_opened   => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.3' }, # halfOpenedConnections
        half_closed   => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.4' }, # halfClosedConnections
        established   => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.5' }, # establishedConnections
        active        => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.6' }, # activeConnections
        total         => { oid => '.1.3.6.1.4.1.17163.1.1.5.2.7' }  # totalConnections
    },
    ex => {
        max_optimized => { oid => '.1.3.6.1.4.1.17163.1.51.2.13.1' }, # shMaxConnections
        optimized     => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.1' }, # optimizedConnections
        passthrough   => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.2' }, # passthroughConnections
        half_opened   => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.3' }, # halfOpenedConnections
        half_closed   => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.4' }, # halfClosedConnections
        established   => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.5' }, # establishedConnections
        active        => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.6' }, # activeConnections
        total         => { oid => '.1.3.6.1.4.1.17163.1.51.5.2.7' } # totalConnections
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            map($_->{oid} . '.0', values(%{$mappings->{common}})),
            map($_->{oid} . '.0', values(%{$mappings->{ex}}))
        ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mappings->{common}, results => $snmp_result, instance => 0);
    if (!defined($result->{optimized})) {
        $result = $options{snmp}->map_instance(mapping => $mappings->{ex}, results => $snmp_result, instance => 0);
    }

    $self->{global} = $result;
    $self->{global}->{optimized_free} = $result->{max_optimized} - $result->{optimized};
    $self->{global}->{prct_optimized} = $result->{optimized} * 100 / $result->{max_optimized};
    $self->{global}->{prct_optimized_free} = 100 - $self->{global}->{prct_optimized};
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

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'established', 'active', 'optimized', 'optimized-prct',
'passthrough', 'half-opened', 'half-closed'.

=back

=cut
