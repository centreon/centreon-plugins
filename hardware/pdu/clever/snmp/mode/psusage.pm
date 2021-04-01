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

package hardware::pdu::clever::snmp::mode::psusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'power', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'Input power : %s W',
                perfdatas => [
                    { label => 'power', value => 'power', template => '%s', 
                      unit => 'W', min => 0 },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'current', template => '%s', 
                      unit => 'A', min => 0 },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'voltage', template => '%s', 
                      unit => 'V', min => 0 },
                ],
            }
        },
    ];
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

my $oid_current = '.1.3.6.1.4.1.30966.1.2.1.6.0';
my $oid_voltage = '.1.3.6.1.4.1.30966.1.2.1.9.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{snmp}->get_leef(oids => [ $oid_current, $oid_voltage ], 
                                          nothing_quit => 1);
    $self->{global} = { current => $result->{$oid_current}, voltage => $result->{$oid_voltage}, 
                        power => $result->{$oid_current} * $result->{$oid_voltage} };
}

1;

__END__

=head1 MODE

Check power source usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'current', 'power', 'voltage'.

=item B<--critical-*>

Threshold critical.
Can be: 'current', 'power', 'voltage'.

=back

=cut
