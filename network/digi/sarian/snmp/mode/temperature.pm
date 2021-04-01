#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and temperatureplication monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.temperatureache.org/licenses/LICENSE-2.0
#
# Unless required by temperatureplicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::digi::sarian::snmp::mode::temperature;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'temperature', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{temperature} = [
        { label => 'device', set => {
                key_values => [ { name => 'device' } ],
                output_template => 'Temp Device : %d °C',
                perfdatas => [
                    { label => 'tempDevice', value => 'device', template => '%d',
                      unit => 'C' },
                ],
            }
        },
        { label => 'processor', set => {
                key_values => [ { name => 'processor' } ],
                output_template => 'Temp Processor : %d °C',
                perfdatas => [
                    { label => 'tempProcessor', value => 'processor', template => '%d',
                      unit => 'C' },
                ],
            }
        },
        { label => 'modem', set => {
                key_values => [ { name => 'modem' } ],
                output_template => 'Temp Modem : %d °C',
                perfdatas => [
                    { label => 'tempModem', value => 'modem', template => '%d',
                      unit => 'C' },
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

my $oid_temperature = '.1.3.6.1.4.1.16378.10000.3.11.0';
my $oid_processorTemperature = '.1.3.6.1.4.1.16378.10000.3.12.0';
my $oid_modemTemperature = '.1.3.6.1.4.1.16378.10000.3.13.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    $self->{temperature} = {};
    $self->{results} = $self->{snmp}->get_leef(oids => [ $oid_temperature, $oid_processorTemperature, $oid_modemTemperature ],
                                               nothing_quit => 1);

    $self->{temperature} = { device => $self->{results}->{$oid_temperature} > -20 ? $self->{results}->{$oid_temperature} : undef,
                             processor => $self->{results}->{$oid_processorTemperature},
                             modem => $self->{results}->{$oid_modemTemperature} };

}

1;

__END__

=head1 MODE

Check Digi equipment temperature (sarian-monitor.mib)

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='processor|modem'

=item B<--warning-*>

Threshold warning.
Can be: 'device', 'modem', 'processor' (C).

=item B<--critical-*>

Threshold critical.
Can be: 'device', 'modem', 'processor' (C).

=back

=cut
