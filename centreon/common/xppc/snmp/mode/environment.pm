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

package hardware::ups::hp::snmp::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'internal-temperature', nlabel => 'environment.internal.temperature.celsius', set => {
                key_values => [ { name => 'internal_temperature' } ],
                output_template => 'internal temperature: %.2f C',
                perfdatas => [
                    { value => 'internal_temperature', template => '%.2f',
                      min => 0, unit => 'C' },
                ],
            }
        },
        { label => 'internal-humidity', nlabel => 'environment.internal.humidity.percentage', set => {
                key_values => [ { name => 'internal_humidity' } ],
                output_template => 'internal humidity: %.2f %%',
                perfdatas => [
                    { value => 'internal_humidity', template => '%.2f', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'remote-temperature', nlabel => 'environment.remote.temperature.celsius', set => {
                key_values => [ { name => 'remote_temperature' } ],
                output_template => 'remote temperature: %.2f C',
                perfdatas => [
                    { value => 'remote_temperature', template => '%.2f',
                      min => 0, unit => 'C' },
                ],
            }
        },
        { label => 'remote-humidity', nlabel => 'environment.remote.humidity.percentage', set => {
                key_values => [ { name => 'remote_humidity' } ],
                output_template => 'remote humidity: %.2f %%',
                perfdatas => [
                    { value => 'remote_humidity', template => '%.2f', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
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

    my $oids = {
        upsEnvAmbientTemp          => '.1.3.6.1.4.1.232.165.3.6.1.0',
        upsEnvAmbientLowerLimit    => '.1.3.6.1.4.1.232.165.3.6.2.0',
        upsEnvAmbientUpperLimit    => '.1.3.6.1.4.1.232.165.3.6.3.0',
        upsEnvAmbientHumidity      => '.1.3.6.1.4.1.232.165.3.6.4.0',
        upsEnvRemoteTemp           => '.1.3.6.1.4.1.232.165.3.6.5.0',
        upsEnvRemoteHumidity       => '.1.3.6.1.4.1.232.165.3.6.6.0',
        upsEnvRemoteTempLowerLimit => '.1.3.6.1.4.1.232.165.3.6.9.0',
        upsEnvRemoteTempUpperLimit => '.1.3.6.1.4.1.232.165.3.6.10.0',
        upsEnvRemoteHumidityLowerLimit => '.1.3.6.1.4.1.232.165.3.6.11.0',
        upsEnvRemoteHumidityUpperLimit => '.1.3.6.1.4.1.232.165.3.6.12.0',
    };
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ values %$oids ], 
        nothing_quit => 1
    );

    $self->{global} = {
        internal_temperature => defined($snmp_result->{$oids->{upsEnvAmbientTemp}}) && $snmp_result->{$oids->{upsEnvAmbientTemp}} ne '' && $snmp_result->{$oids->{upsEnvAmbientTemp}} != 0 ? 
            $snmp_result->{$oids->{upsEnvAmbientTemp}} : undef,
        internal_humidity => defined($snmp_result->{$oids->{upsEnvAmbientHumidity}}) && $snmp_result->{$oids->{upsEnvAmbientHumidity}} ne '' && $snmp_result->{$oids->{upsEnvAmbientHumidity}} != 0 ?
            $snmp_result->{$oids->{upsEnvAmbientHumidity}} : undef,
        remote_temperature => defined($snmp_result->{$oids->{upsEnvRemoteTemp}}) && $snmp_result->{$oids->{upsEnvRemoteTemp}} ne '' && $snmp_result->{$oids->{upsEnvRemoteTemp}} != 0 ? 
            $snmp_result->{$oids->{upsEnvRemoteTemp}} : undef,
        remote_humidity =>  defined($snmp_result->{$oids->{upsEnvRemoteHumidity}}) && $snmp_result->{$oids->{upsEnvRemoteHumidity}} ne '' && $snmp_result->{$oids->{upsEnvRemoteHumidity}} != 0 ? 
            $snmp_result->{$oids->{upsEnvRemoteHumidity}} : undef,
    };

    if (!defined($self->{option_results}->{'critical-environment-internal-temperature-celsius'}) || $self->{option_results}->{'critical-environment-internal-temperature-celsius'} eq '') {
        my $crit_val = '';
        $crit_val = $snmp_result->{$oids->{upsEnvAmbientLowerLimit}} . ':' 
            if (defined($snmp_result->{$oids->{upsEnvAmbientLowerLimit}}) && 
                $snmp_result->{$oids->{upsEnvAmbientLowerLimit}} ne '' && $snmp_result->{$oids->{upsEnvAmbientLowerLimit}} != 0);
        $crit_val .= $snmp_result->{$oids->{upsEnvAmbientUpperLimit}} 
            if (defined($snmp_result->{$oids->{upsEnvAmbientUpperLimit}}) && 
                $snmp_result->{$oids->{upsEnvAmbientUpperLimit}} ne '' && $snmp_result->{$oids->{upsEnvAmbientUpperLimit}} != 0);
        $self->{perfdata}->threshold_validate(label => 'critical-environment-internal-temperature-celsius', value => $crit_val);
    }

    if (!defined($self->{option_results}->{'critical-environment-remote-temperature-celsius'}) || $self->{option_results}->{'critical-environment-remote-temperature-celsius'} eq '') {
        my $crit_val = '';
        $crit_val = $snmp_result->{$oids->{upsEnvRemoteTempLowerLimit}} . ':' 
            if (defined($snmp_result->{$oids->{upsEnvRemoteTempLowerLimit}}) && 
                $snmp_result->{$oids->{upsEnvRemoteTempLowerLimit}} ne '' && $snmp_result->{$oids->{upsEnvRemoteTempLowerLimit}} != 0);
        $crit_val .= $snmp_result->{$oids->{upsEnvRemoteTempUpperLimit}} 
            if (defined($snmp_result->{$oids->{upsEnvRemoteTempUpperLimit}}) && 
                $snmp_result->{$oids->{upsEnvRemoteTempUpperLimit}} ne '' && $snmp_result->{$oids->{upsEnvRemoteTempUpperLimit}} != 0);
        $self->{perfdata}->threshold_validate(label => 'critical-environment-remote-temperature-celsius', value => $crit_val);
    }
}

1;

__END__

=head1 MODE

Check environment.

=over 8

=item B<--warning-*> B<--critical-*>

Can be: 'internal-temperature', 'internal-humidity',
'remote-temperature', 'remote-humidity'.

=back

=cut
