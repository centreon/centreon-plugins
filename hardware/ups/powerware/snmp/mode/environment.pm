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

package hardware::ups::powerware::snmp::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'temperature', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'Ambiant Temperature: %.2f C',
                perfdatas => [
                    { label => 'temperature', value => 'temperature_absolute', template => '%.2f',
                      min => 0, unit => 'C' },
                ],
            }
        },
        { label => 'humidity', set => {
                key_values => [ { name => 'humidity' } ],
                output_template => 'Humidity: %.2f %%',
                perfdatas => [
                    { label => 'humidity', value => 'humidity_absolute', template => '%.2f', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
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

    my $oids = {
        xupsEnvAmbientTemp          => '.1.3.6.1.4.1.534.1.6.1.0',
        xupsEnvAmbientLowerLimit    => '.1.3.6.1.4.1.534.1.6.2.0',
        xupsEnvAmbientUpperLimit    => '.1.3.6.1.4.1.534.1.6.3.0',
        xupsEnvAmbientHumidity      => '.1.3.6.1.4.1.534.1.6.4.0',
        xupsEnvRemoteTemp           => '.1.3.6.1.4.1.534.1.6.5.0',
        xupsEnvRemoteHumidity       => '.1.3.6.1.4.1.534.1.6.6.0',
        xupsEnvRemoteTempLowerLimit => '.1.3.6.1.4.1.534.1.6.9.0',
        xupsEnvRemoteTempUpperLimit => '.1.3.6.1.4.1.534.1.6.10.0',
        xupsEnvRemoteHumidityLowerLimit => '.1.3.6.1.4.1.534.1.6.11.0',
        xupsEnvRemoteHumidityUpperLimit => '.1.3.6.1.4.1.534.1.6.11.0',
    };
    my $snmp_result = $options{snmp}->get_leef(oids => [
        values %$oids
        ], nothing_quit => 1);

    $self->{global} = {};
    $self->{global}->{temperature} = defined($snmp_result->{$oids->{xupsEnvAmbientTemp}}) && $snmp_result->{$oids->{xupsEnvAmbientTemp}} ne '' && $snmp_result->{$oids->{xupsEnvAmbientTemp}} != 0 ?
        $snmp_result->{$oids->{xupsEnvAmbientTemp}} : 
            (defined($snmp_result->{$oids->{xupsEnvRemoteTemp}}) && $snmp_result->{$oids->{xupsEnvRemoteTemp}} ne '' && $snmp_result->{$oids->{xupsEnvRemoteTemp}} != 0 ? 
                $snmp_result->{$oids->{xupsEnvRemoteTemp}} : undef);
    $self->{global}->{humidity} = defined($snmp_result->{$oids->{xupsEnvAmbientHumidity}}) && $snmp_result->{$oids->{xupsEnvAmbientHumidity}} ne '' && $snmp_result->{$oids->{xupsEnvAmbientHumidity}} != 0 ?
        $snmp_result->{$oids->{xupsEnvAmbientHumidity}} : 
            (defined($snmp_result->{$oids->{xupsEnvRemoteHumidity}}) && $snmp_result->{$oids->{xupsEnvRemoteHumidity}} ne '' && $snmp_result->{$oids->{xupsEnvRemoteHumidity}} != 0 ? 
                $snmp_result->{$oids->{xupsEnvRemoteHumidity}} : undef);

    if (!defined($self->{option_results}->{'critical-temperature'}) || $self->{option_results}->{'critical-temperature'} eq '') {
        my $crit_val = '';
        $crit_val = $snmp_result->{$oids->{xupsEnvAmbientLowerLimit}} . ':' 
            if (defined($snmp_result->{$oids->{xupsEnvAmbientLowerLimit}}) && 
                $snmp_result->{$oids->{xupsEnvAmbientLowerLimit}} ne '' && $snmp_result->{$oids->{xupsEnvAmbientLowerLimit}} != 0);
        $crit_val .= $snmp_result->{$oids->{xupsEnvAmbientUpperLimit}} 
            if (defined($snmp_result->{$oids->{xupsEnvAmbientUpperLimit}}) && 
                $snmp_result->{$oids->{xupsEnvAmbientUpperLimit}} ne '' && $snmp_result->{$oids->{xupsEnvAmbientUpperLimit}} != 0);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature', value => $crit_val);
    }
}

1;

__END__

=head1 MODE

Check environment (temperature and humidity) (XUPS-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'temperature', 'humidity'.

=item B<--critical-*>

Threshold critical.
Can be: 'temperature', 'humidity'.

=back

=cut
