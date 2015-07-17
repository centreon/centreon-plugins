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

package hardware::ups::mge::snmp::mode::batterystatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_battery_status = (
    '.1.3.6.1.4.1.705.1.5.9.0' => 'BatteryFaultBattery', 
    '.1.3.6.1.4.1.705.1.5.10.0' => 'BatteryNoBattery', 
    '.1.3.6.1.4.1.705.1.5.11.0' => 'BatteryReplacement', 
    '.1.3.6.1.4.1.705.1.5.12.0' => 'BatteryUnavailableBattery', 
    '.1.3.6.1.4.1.705.1.5.13.0' => 'BatteryNotHighCharge', 
    '.1.3.6.1.4.1.705.1.5.14.0' => 'BatteryLowBattery', 
    '.1.3.6.1.4.1.705.1.5.15.0' => 'BatteryChargerFault', 
    '.1.3.6.1.4.1.705.1.5.16.0' => 'BatteryLowCondition', 
    '.1.3.6.1.4.1.705.1.5.17.0' => 'BatteryLowRecharge', 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"       => { name => 'warning', },
                                  "critical:s"      => { name => 'critical', },
                                  "filter-status:s" => { name => 'filter_status', },
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
    
    my $oid_upsmgBattery = '.1.3.6.1.4.1.705.1.5';
    my $oid_upsmgBatteryRemainingTime = '.1.3.6.1.4.1.705.1.5.1.0'; # in seconds
    my $oid_upsmgBatteryLevel = '.1.3.6.1.4.1.705.1.5.2.0';
    my $oid_upsmgBatteryVoltage = '.1.3.6.1.4.1.705.1.5.5.0'; # in dV
    my $oid_upsmgBatteryCurrent = '.1.3.6.1.4.1.705.1.5.6.0'; # in dA
    my $oid_upsmgBatteryTemperature = '.1.3.6.1.4.1.705.1.5.7.0'; # in degrees Centigrade
    
    my $result = $self->{snmp}->get_table(oid => $oid_upsmgBattery, nothing_quit => 1);

    my $current = defined($result->{$oid_upsmgBatteryCurrent}) ? $result->{$oid_upsmgBatteryCurrent} * 0.1 : 0;
    my $voltage = defined($result->{$oid_upsmgBatteryVoltage}) ? $result->{$oid_upsmgBatteryVoltage} * 0.1 : 0;
    my $min_remain = defined($result->{$oid_upsmgBatteryRemainingTime}) ? int($result->{$oid_upsmgBatteryRemainingTime} / 60) : 'unknown';
    my $charge_remain = defined($result->{$oid_upsmgBatteryLevel}) ? $result->{$oid_upsmgBatteryLevel} : 'unknown';
    my $temp = defined($result->{$oid_upsmgBatteryTemperature}) ? $result->{$oid_upsmgBatteryTemperature} : 0;
  
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Battery status is ok"));
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %map_battery_status)) {
        next if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' && $map_battery_status{$oid} =~ /$self->{option_results}->{filter_status}/);
        if (defined($result->{$oid}) && $result->{$oid} == 1) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Battery status is '%s'", $map_battery_status{$oid}));
        }
    }
    
    my $exit_code = 'ok';
    if ($charge_remain ne 'unknown') {
        $exit_code = $self->{perfdata}->threshold_check(value => $charge_remain, 
                                                        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->perfdata_add(label => 'load', unit => '%',
                                      value => $charge_remain,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Charge remaining: %s%% (%s minutes remaining)", $charge_remain, $min_remain));
    
    if ($current != 0) {
        $self->{output}->perfdata_add(label => 'current', unit => 'A',
                                      value => $current,
                                      );
    }
    if ($voltage != 0) {
        $self->{output}->perfdata_add(label => 'voltage', unit => 'V',
                                      value => $voltage,
                                      );
    }
    if ($temp != 0) {
        $self->{output}->perfdata_add(label => 'temp', unit => 'C',
                                      value => $temp,
                                      );
    }
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Battery Status and battery charge remaining.

=over 8

=item B<--warning>

Threshold warning in percent of charge remaining.

=item B<--critical>

Threshold critical in percent of charge remaining.

=item B<--filter-status>

Filter on status. (can be a regexp)

=back

=cut
