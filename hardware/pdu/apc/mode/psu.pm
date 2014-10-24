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

package hardware::pdu::apc::mode::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states_psu_1 = (
    1 => ['powerSupplyOneOk', 'OK'],
    2 => ['powerSupplyOneFailed', 'CRITICAL'],
);

my %states_psu_2 = (
    1 => ['powerSupplyTwoOk', 'OK'],
    2 => ['powerSupplyTwoFailed', 'CRITICAL'],
);

my %alarms_psu = (
    1 => ['allAvailablePowerSuppliesOK', 'OK'],
    2 => ['powerSupplyOneFailed', 'CRITICAL'],
    3 => ['powerSupplyTwoFailed', 'CRITICAL'],
    4 => ['powerSupplyOneandTwoFailed', 'CRITICAL'],
);

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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_rPDUPowerSupply1Status = '.1.3.6.1.4.1.318.1.1.12.4.1.1.0';
    my $oid_rPDUPowerSupply2Status = '.1.3.6.1.4.1.318.1.1.12.4.1.2.0';
    my $oid_rPDUPowerSupplyAlarm = '.1.3.6.1.4.1.318.1.1.12.4.1.3.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_rPDUPowerSupply1Status, $oid_rPDUPowerSupply2Status, $oid_rPDUPowerSupplyAlarm], nothing_quit => 1);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All power supplies are ok');

    my $psu_alarm = $result->{$oid_rPDUPowerSupplyAlarm};
    my $psu1_status = $result->{$oid_rPDUPowerSupply2Status};
    my $psu2_status = $result->{$oid_rPDUPowerSupplyAlarm};

	$self->{output}->output_add(long_msg => sprintf("Power supply 1 state is '%s'", ${$states_psu_1{$psu1_status}}[0]));
	$self->{output}->output_add(long_msg => sprintf("Power supply 2 state is '%s'", ${$states_psu_2{$psu2_status}}[0]));
	
    if (${$alarms_psu{$psu_alarm}}[1] ne 'OK') {
        $self->{output}->output_add(severity => ${$alarms_psu{$psu_alarm}}[1],
                                    short_msg => sprintf("Power supplies state is '%s'",
                                                        ${$alarms_psu{$psu_alarm}}[0]));
    }
    if (${$states_psu_1{$psu1_status}}[1] ne 'OK') {
        $self->{output}->output_add(severity => ${$states_psu_1{$psu1_status}}[1],
                                    short_msg => sprintf("Power supply 1 state is '%s'",
                                                        ${$states_psu_1{$psu1_status}}[0]));
    }
    if (${$states_psu_2{$psu2_status}}[1] ne 'OK') {
        $self->{output}->output_add(severity => ${$states_psu_2{$psu2_status}}[1],
                                    short_msg => sprintf("Power supply 2 state is '%s'",
                                                        ${$states_psu_2{$psu2_status}}[0]));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC power supplies.

=over 8

=back

=cut
    
