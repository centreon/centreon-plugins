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

package network::mikrotik::snmp::mode::voltages;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_voltage_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => '1min', set => {
                key_values => [ { name => '1min' } ],
                output_template => '1 minute average : %.1f V',
                perfdatas => [
                    { label => 'voltage_1min_avg', value => '1min_absolute', voltagelate => '%.2f',
                      min => 0, max => 9999, unit => 'V' },
                ],
            }
        }
    ];
}

sub prefix_voltage_output {
    my ($self, %options) = @_;
    
    return "voltage ";
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

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_AvgvoltageMikro = '.1.3.6.1.4.1.14988.1.1.3.8.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [
            $oid_AvgvoltageMikro
        ], nothing_quit => 1);

    $self->{global} = { '1min' => $snmp_result->{$oid_AvgvoltageMikro}/10};
}

1;

__END__

=head1 MODE

Check voltage.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
