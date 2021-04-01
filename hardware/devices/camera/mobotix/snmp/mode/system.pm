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

package hardware::devices::camera::mobotix::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'system', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{system} = [
        { label => 'sdcard-usage', nlabel => 'system.sdcard.usage.percent', set => {
                key_values => [ { name => 'storageArchiveBufferFillLevel', no_value => -1 } ],
                output_template => 'sd card usage: %.2f %%',
                perfdatas => [
                    { value => 'storageArchiveBufferFillLevel', template => '%d', min => 0, max => 100,
                      unit => '%' },
                ],
            }
        },
        { label => 'temperature-internal', nlabel => 'system.temperature.internal.celsius', set => {
                key_values => [ { name => 'statusTemperatureCameraC', no_value => -1000 } ],
                output_template => 'internal temperature: %s C',
                perfdatas => [
                    { value => 'statusTemperatureCameraC', template => '%s', unit => 'C' },
                ],
            }
        },
        { label => 'temperature-external', nlabel => 'system.temperature.external.celsius', set => {
                key_values => [ { name => 'statusTemperatureOutsideC', no_value => -1000 } ],
                output_template => 'external temperature: %s C',
                perfdatas => [
                    { value => 'statusTemperatureOutsideC', template => '%s', unit => 'C' },
                ],
            }
        },
        { label => 'temperature-gps', nlabel => 'system.temperature.gps.celsius', set => {
                key_values => [ { name => 'statusTemperatureGpsC', no_value => -1000 } ],
                output_template => 'gps temperature: %s C',
                perfdatas => [
                    { value => 'statusTemperatureGpsC', template => '%s', unit => 'C' },
                ],
            }
        },
        { label => 'illumination-right', nlabel => 'system.illumination.right.lux', set => {
                key_values => [ { name => 'statusSensorIlluminationR', no_value => -1000 } ],
                output_template => 'illumination right: %s lx',
                perfdatas => [
                    { value => 'statusSensorIlluminationR', template => '%s', unit => 'lx' },
                ],
            }
        },
        { label => 'illumination-left', nlabel => 'system.illumination.left.lux', set => {
                key_values => [ { name => 'statusSensorIlluminationL', no_value => -1000 } ],
                output_template => 'illumination left: %s lx',
                perfdatas => [
                    { value => 'statusSensorIlluminationL', template => '%s', unit => 'lx' },
                ],
            }
        },
        { label => 'video-framerate', nlabel => 'system.video.framerate.persecond', set => {
                key_values => [ { name => 'videoMainCurrentFrameRate', no_value => -1000 } ],
                output_template => 'video framerate: %s fps',
                perfdatas => [
                    { value => 'videoMainCurrentFrameRate', template => '%s', unit => 'fps' },
                ],
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
        storageArchiveBufferFillLevel => { oid => '.1.3.6.1.4.1.21701.2.3.8' },
        statusTemperatureCameraC      => { oid => '.1.3.6.1.4.1.21701.2.7.2.1.1' },
        statusTemperatureOutsideC     => { oid => '.1.3.6.1.4.1.21701.2.7.2.2.1' },
        statusTemperatureGpsC         => { oid => '.1.3.6.1.4.1.21701.2.7.2.4.1' },
        statusSensorIlluminationR     => { oid => '.1.3.6.1.4.1.21701.2.7.3.1' },
        statusSensorIlluminationL     => { oid => '.1.3.6.1.4.1.21701.2.7.3.2' },
        videoMainCurrentFrameRate     => { oid => '.1.3.6.1.4.1.21701.2.7.5.1.2' }
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{system} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sdcard-usage', 'temperature-internal', 'temperature-external',
'temperature-gps', 'illumination-right', 'illumination-left', 'video-framerate'.

=back

=cut
