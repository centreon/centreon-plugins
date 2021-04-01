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

package hardware::ups::mge::snmp::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'temperature', nlabel => 'hardware.sensor.temperature.celsius', set => {
                key_values => [ { name => 'temperature', no_value => 0, } ],
                output_template => 'Ambiant Temperature: %.2f C', output_error_template => 'Ambiant Temperature: %s',
                perfdatas => [
                    { value => 'temperature', label => 'temperature', template => '%.2f',
                      unit => 'C' },
                ],
            }
        },
        { label => 'humidity', nlabel => 'hardware.sensor.humidity.percentage', set => {
                key_values => [ { name => 'humidity', no_value => 0 } ],
                output_template => 'Humidity: %.2f %%', output_error_template => 'Humidity: %s',
                perfdatas => [
                    { value => 'humidity', label => 'humidity', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    my $values_ok = 0;
    
    my $oid_upsmgEnvironAmbientTemp = '.1.3.6.1.4.1.705.1.8.1.0'; # in 0.1 degree centigrade
    my $oid_upsmgEnvironAmbientHumidity = '.1.3.6.1.4.1.705.1.8.2.0'; # in 0.1 %
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_upsmgEnvironAmbientTemp, $oid_upsmgEnvironAmbientHumidity],
        nothing_quit => 1
    );

    $self->{global} = {};     
    if (defined($snmp_result->{$oid_upsmgEnvironAmbientTemp}) && $snmp_result->{$oid_upsmgEnvironAmbientTemp} ne '' &&
        $snmp_result->{$oid_upsmgEnvironAmbientTemp} != 0) {
        $self->{global}->{temperature} = $snmp_result->{$oid_upsmgEnvironAmbientTemp} / 10;
        $values_ok++;
    }
    if (defined($snmp_result->{$oid_upsmgEnvironAmbientHumidity}) && $snmp_result->{$oid_upsmgEnvironAmbientHumidity} ne '' &&
        $snmp_result->{$oid_upsmgEnvironAmbientHumidity} != 0) {
        $self->{global}->{humidity} = $snmp_result->{$oid_upsmgEnvironAmbientHumidity} / 10;
        $values_ok++;
    }
    
    if ($values_ok == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot get temperature and humidity values.");
        $self->{output}->option_exit();
    }    
}

1;

__END__

=head1 MODE

Check environment (temperature and humidity).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'temperature', 'humidity'.

=item B<--critical-*>

Threshold critical.
Can be: 'temperature', 'humidity'.

=back

=cut
