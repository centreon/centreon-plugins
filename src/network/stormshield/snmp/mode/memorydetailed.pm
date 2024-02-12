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

package network::stormshield::snmp::mode::memorydetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_memory_output {
    my ($self, %options) = @_;

    return 'Memory usage ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_memory_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'host', nlabel => 'memory.protected_host.percentage', set => {
                key_values => [ { name => 'host' } ],
                output_template => 'protected host: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'frag', nlabel => 'memory.fragmented.percentage', set => {
                key_values => [ { name => 'frag' } ],
                output_template => 'fragmented: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'conn', nlabel => 'memory.connections.percentage', set => {
                key_values => [ { name => 'conn' } ],
                output_template => 'connections: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'icmp', nlabel => 'memory.icmp.percentage', set => {
                key_values => [ { name => 'icmp' } ],
                output_template => 'icmp: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'dtrack', nlabel => 'memory.data_tracking.percentage', set => {
                key_values => [ { name => 'dtrack' } ],
                output_template => 'data tracking: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'dyn', nlabel => 'memory.dynamic.percentage', set => {
                key_values => [ { name => 'dyn' } ],
                output_template => 'dynamic: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'etherstate', nlabel => 'memory.ether_state.percentage', set => {
                key_values => [ { name => 'ether_state' } ],
                output_template => 'ether state: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_snsMem = '.1.3.6.1.4.1.11256.1.10.3.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_snsMem ],
        nothing_quit => 1
    );

    # host,frag,icmp,conn,dtrack,dyn
    # host,frag,icmp,conn,ether_state,dtrack,dyn

    my @values = split(/,/, $snmp_result->{$oid_snsMem});
    my $fields = scalar(@values);
    if ($fields == 7) {
        $self->{global} = { 
            total => $values[0] + $values[1] + $values[2] + $values[3] + $values[4] + $values[5] + $values[6],
            host => $values[0],
            frag => $values[1],
            icmp => $values[2],
            conn => $values[3],
            ether_state => $values[4], 
            dtrack => $values[5],
            dyn => $values[6]
        };
    } elsif ($fields == 6) {
        $self->{global} = { 
            total => $values[0] + $values[1] + $values[2] + $values[3] + $values[4] + $values[5],
            host => $values[0],
            frag => $values[1],
            icmp => $values[2],
            conn => $values[3],
            dtrack => $values[4],
            dyn => $values[5]
        };
    }
}

1;

__END__

=head1 MODE

Check memory detailed.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'host', 'frag', 'conn', 'icmp',
'dtrack', 'dyn', 'etherstate'. 

=back

=cut
