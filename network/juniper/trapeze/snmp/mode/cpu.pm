#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::trapeze::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{cpu} = [
       { label => 'average', set => {
                key_values => [ { name => 'trpzSysCpuAverageLoad' } ],
                output_template => 'average : %.2f %%',
                perfdatas => [
                    { label => 'cpu_average', value => 'trpzSysCpuAverageLoad', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '1m', set => {
                key_values => [ { name => 'trpzSysCpuLastMinuteLoad' } ],
                output_template => '1 minute : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1m', value => 'trpzSysCpuLastMinuteLoad', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '5m', set => {
                key_values => [ { name => 'trpzSysCpuLast5MinutesLoad' } ],
                output_template => '5 minutes : %.2f %%',
                perfdatas => [
                    { label => 'cpu_5m', value => 'trpzSysCpuLast5MinutesLoad', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '1h', set => {
                key_values => [ { name => ' trpzSysCpuLastHourLoad' } ],
                output_template => '1 hour : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1h', value => ' trpzSysCpuLastHourLoad', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU Usage ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    #  TRAPEZE-NETWORKS-SYSTEM-MIB
    my $oid_trpzSysCpuAverageLoad = '.1.3.6.1.4.1.14525.4.8.1.1.5.0';
    my $oid_trpzSysCpuLastMinuteLoad = '.1.3.6.1.4.1.14525.4.8.1.1.11.2.0';
    my $oid_trpzSysCpuLast5MinutesLoad = '.1.3.6.1.4.1.14525.4.8.1.1.11.3.0';
    my $oid_trpzSysCpuLastHourLoad = '.1.3.6.1.4.1.14525.4.8.1.1.11.4.0';
   
    my $results = $options{snmp}->get_leef(oids => [$oid_trpzSysCpuAverageLoad, $oid_trpzSysCpuLastMinuteLoad, 
                                                    $oid_trpzSysCpuLast5MinutesLoad, $oid_trpzSysCpuLastHourLoad ],
                                           nothing_quit => 1);
       
    $self->{cpu} = { trpzSysCpuAverageLoad => $results->{$oid_trpzSysCpuAverageLoad},
                     trpzSysCpuLastMinuteLoad => $results->{$oid_trpzSysCpuLastMinuteLoad},
                     trpzSysCpuLast5MinutesLoad => $results->{$oid_trpzSysCpuLast5MinutesLoad},
                     trpzSysCpuLastHourLoad => $results->{$oid_trpzSysCpuLastHourLoad},
                     };
}

1;

__END__

=head1 MODE

Check CPU usage

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1m|5m)$'

=item B<--warning-*>

Threshold warning.
Can be: '1m', '5m', '1h, 'average'

=item B<--critical-*>

Threshold critical.
Can be: '1m', '5m', '1h', 'average'

=back

=cut
