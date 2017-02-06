#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::raisecom::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{cpu} = [
       { label => '1s', set => {
                key_values => [ { name => 'raisecomCPUUtilization1sec' } ],
                output_template => '1 seconde : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1s', value => 'raisecomCPUUtilization1sec_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '1m', set => {
                key_values => [ { name => 'raisecomCPUUtilization1min' } ],
                output_template => '1 minute : %.2f %%',
                perfdatas => [
                    { label => 'cpu_1m', value => 'raisecomCPUUtilization1min_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '10m', set => {
                key_values => [ { name => 'raisecomCPUUtilization10min' } ],
                output_template => '10 minutes : %.2f %%',
                perfdatas => [
                    { label => 'cpu_10m', value => 'raisecomCPUUtilization10min_absolute', template => '%.2f',
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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    # 
    my $oid_raisecomCPUUtilization1sec = '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1.3.1';
    my $oid_raisecomCPUUtilization1min = '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1.3.3';
    my $oid_raisecomCPUUtilization10min = '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1.3.4';
   
    my $results = $options{snmp}->get_leef(oids => [$oid_raisecomCPUUtilization1sec, $oid_raisecomCPUUtilization1min, 
                                                    $oid_raisecomCPUUtilization10min ],
                                           nothing_quit => 1);
       
    $self->{cpu} = { raisecomCPUUtilization1sec => $results->{$oid_raisecomCPUUtilization1sec},
                     raisecomCPUUtilization1min => $results->{$oid_raisecomCPUUtilization1min},
                     raisecomCPUUtilization10min => $results->{$oid_raisecomCPUUtilization10min},
                     };
}

1;

__END__

=head1 MODE

Check CPU usage

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1s|1m)$'

=item B<--warning-*>

Threshold warning.
Can be: '1s', '1m', '10m'

=item B<--critical-*>

Threshold critical.
Can be: '1s', '1m', '10m'

=back

=cut
