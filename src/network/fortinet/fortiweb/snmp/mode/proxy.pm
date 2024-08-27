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

package network::fortinet::fortiweb::snmp::mode::proxy;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking proxy';
}

sub prefix_connections_output {
    my ($self, %options) = @_;

    return 'number of connections ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'proxy', type => 3, cb_long_output => 'proxy_long_output', indent_long_output => '    ',
            group => [
                { name => 'connection', type => 0, cb_prefix_output => 'prefix_connections_output', display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'service', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'connections', nlabel => 'proxy.connections.count', set => {
                key_values => [ { name => 'con_current' } ],
                output_template => 'current: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'connections-average', nlabel => 'proxy.connections.persecond', set => {
                key_values => [ { name => 'con_psec' } ],
                output_template => 'average: %s/s',
                perfdatas => [
                    { template => '%s', unit => '/s', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{service} = [
        { label => 'services', nlabel => 'proxy.services.count', set => {
                key_values => [ { name => 'services_num' } ],
                output_template => 'number of services: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        services_num => { oid => '.1.3.6.1.4.1.12356.107.3.5' }, # fwServiceNumber
        con_current  => { oid => '.1.3.6.1.4.1.12356.107.3.7' }, # fwTotalConnectNumber
        con_psec     => { oid => '.1.3.6.1.4.1.12356.107.3.8' }  # fwTotalConnectNumberPerSecond
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'proxy usage is ok');

    $self->{proxy} = {
        global => {
            connection => {
                con_current => $result->{con_current},
                con_psec => $result->{con_psec}
            },
            service => { services_num => $result->{services_num} }
        }
    };
}

1;

__END__

=head1 MODE

Check proxy.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='connections'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections', 'connections-average', 'services'.

=back

=cut
