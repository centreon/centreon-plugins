#
# Copyright 2015 Centreon (http://www.centreon.com/)
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
    
