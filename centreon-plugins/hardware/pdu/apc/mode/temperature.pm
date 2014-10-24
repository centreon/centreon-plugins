################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::pdu::apc::mode::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['notPresent', 'OK'],
    2 => ['belowMin', 'CRITICAL'],
    3 => ['belowLow', 'WARNING'],
    4 => ['normal', 'OK'],
    5 => ['aboveHigh', 'WARNING'],
    6 => ['aboveMax', 'CRITICAL'],
);

my %type = (
    1 => 'temperatureOnly',
    2 => 'temperatureHumidity'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "warning:s"         => { name => 'warning', },
                                    "critical:s"        => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_rPDU2SensorTempHumidityStatusName = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.3';
    my $oid_rPDU2SensorTempHumidityStatusNumber = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.4';
    my $oid_rPDU2SensorTempHumidityStatusType = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.5';
    my $oid_rPDU2SensorTempHumidityStatusTempC = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.8';
    my $oid_rPDU2SensorTempHumidityStatusTempStatus = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.9';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_rPDU2SensorTempHumidityStatusName },
                                                            { oid => $oid_rPDU2SensorTempHumidityStatusNumber },
                                                            { oid => $oid_rPDU2SensorTempHumidityStatusTempC },
                                                            { oid => $oid_rPDU2SensorTempHumidityStatusTempStatus },
                                                         ],
                                                         , nothing_quit => 1);

    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All temperature sensors are ok');

    foreach my $oid (keys %{$self->{results}->{ $oid_rPDU2SensorTempHumidityStatusName}}) {    
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $sensor_name = $self->{results}->{ $oid_rPDU2SensorTempHumidityStatusName}->{$oid};
        my $sensor_number = $self->{results}->{$oid_rPDU2SensorTempHumidityStatusNumber}->{$oid_rPDU2SensorTempHumidityStatusNumber . '.' . $instance};
        my $sensor_temperature = $self->{results}->{$oid_rPDU2SensorTempHumidityStatusTempC}->{$oid_rPDU2SensorTempHumidityStatusTempC . '.' . $instance} / 10;
        my $sensor_status = $self->{results}->{$oid_rPDU2SensorTempHumidityStatusTempStatus}->{$oid_rPDU2SensorTempHumidityStatusTempStatus . '.' . $instance};

        $self->{output}->output_add(long_msg => sprintf("Temperature sensor #%d '%s' is '%.1fC'", 
                                            $sensor_number, $sensor_name, $sensor_temperature));
		$self->{output}->perfdata_add(label => 'temp' . $sensor_number,
                                      unit => 'C',
                                      value => $sensor_temperature,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
                                      
        my $exit = $self->{perfdata}->threshold_check(value => $sensor_temperature, 
                                                      threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
                                                      
		if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature sensor #%d '%s' is '%.1fC'", 
                                                             $sensor_number, $sensor_name, $sensor_temperature));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC temperature sensors.

=over 8

=back

=cut
    
