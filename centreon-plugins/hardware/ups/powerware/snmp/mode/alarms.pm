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

package hardware::ups::powerware::snmp::mode::alarms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

my %alarm_type_map = (
    '.1.3.6.1.4.1.534.1.7.3' => 'OnBattery',
    '.1.3.6.1.4.1.534.1.7.4' => 'LowBattery',
    '.1.3.6.1.4.1.534.1.7.5' => 'UtilityPowerRestored',
    '.1.3.6.1.4.1.534.1.7.6' => 'ReturnFromLowBattery',
    '.1.3.6.1.4.1.534.1.7.7' => 'OutputOverload',
    '.1.3.6.1.4.1.534.1.7.8' => 'InternalFailure',
    '.1.3.6.1.4.1.534.1.7.9' => 'BatteryDischarged',
    '.1.3.6.1.4.1.534.1.7.10' => 'InverterFailure',
    '.1.3.6.1.4.1.534.1.7.11' => 'OnBypass',
    '.1.3.6.1.4.1.534.1.7.12' => 'BypassNotAvailable',
    '.1.3.6.1.4.1.534.1.7.13' => 'OutputOff',
    '.1.3.6.1.4.1.534.1.7.14' => 'InputFailure',
    '.1.3.6.1.4.1.534.1.7.15' => 'BuildingAlarm',
    '.1.3.6.1.4.1.534.1.7.16' => 'ShutdownImminent',
    '.1.3.6.1.4.1.534.1.7.17' => 'OnInverter',
    '.1.3.6.1.4.1.534.1.7.20' => 'BreakerOpen',
    '.1.3.6.1.4.1.534.1.7.21' => 'AlarmEntryAdded',
    '.1.3.6.1.4.1.534.1.7.22' => 'AlarmEntryRemoved',
    '.1.3.6.1.4.1.534.1.7.23' => 'AlarmBatteryBad',
    '.1.3.6.1.4.1.534.1.7.24' => 'OutputOffAsRequested',
    '.1.3.6.1.4.1.534.1.7.25' => 'DiagnosticTestFailed',
    '.1.3.6.1.4.1.534.1.7.26' => 'CommunicationsLost',
    '.1.3.6.1.4.1.534.1.7.27' => 'UpsShutdownPending',
    '.1.3.6.1.4.1.534.1.7.28' => 'AlarmTestInProgress',
    '.1.3.6.1.4.1.534.1.7.29' => 'AmbientTempBad',
    '.1.3.6.1.4.1.534.1.7.30' => 'LossOfRedundancy',
    '.1.3.6.1.4.1.534.1.7.31' => 'AlarmTempBad',
    '.1.3.6.1.4.1.534.1.7.32' => 'AlarmChargerFailed',
    '.1.3.6.1.4.1.534.1.7.33' => 'AlarmFanFailure',
    '.1.3.6.1.4.1.534.1.7.34' => 'AlarmFuseFailure',
    '.1.3.6.1.4.1.534.1.7.35' => 'PowerSwitchBad',
    '.1.3.6.1.4.1.534.1.7.36' => 'ModuleFailure',
    '.1.3.6.1.4.1.534.1.7.37' => 'OnAlternatePowerSource',
    '.1.3.6.1.4.1.534.1.7.38' => 'AltPowerNotAvailable',
    '.1.3.6.1.4.1.534.1.7.39' => 'NoticeCondition',
    '.1.3.6.1.4.1.534.1.7.40' => 'RemoteTempBad',
    '.1.3.6.1.4.1.534.1.7.41' => 'RemoteHumidityBad',
    '.1.3.6.1.4.1.534.1.7.42' => 'AlarmOutputBad',
    '.1.3.6.1.4.1.534.1.7.43' => 'AlarmAwaitingPower',
    '.1.3.6.1.4.1.534.1.7.44' => 'OnMaintenanceBypass',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-type:s"       => { name => 'filter_type', 
                                                             default => '^(?!(UtilityPowerRestored|NoticeCondition|ReturnFromLowBattery|AlarmEntryAdded|AlarmEntryRemoved))' },
                                  "memory"              => { name => 'memory' },
                                  "warning"             => { name => 'warning' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}


sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    my $datas = {};
    my $last_time;
    my $exit = defined($self->{option_results}->{warning}) ? 'WARNING' : 'CRITICAL';
    my ($num_alarms_checked, $num_errors) = (0, 0);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_ups_powerware_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No new problems detected.");
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems detected.");
    }
    
    my $oid_xupsAlarmEntry = '.1.3.6.1.4.1.534.1.7.2.1';
    my $oid_xupsAlarmDescr = '.1.3.6.1.4.1.534.1.7.2.1.2';
    my $oid_xupsAlarmTime = '.1.3.6.1.4.1.534.1.7.2.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_xupsAlarmEntry);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_xupsAlarmDescr\.(\d+)$/);
        my $instance = $1;

        my $type = $alarm_type_map{$result->{$key}};
        my $time = $result->{$oid_xupsAlarmTime . '.' . $instance};
        
        if (defined($self->{option_results}->{memory})) {
            $datas->{$instance . '_type'} = $type;
            $datas->{$instance . '_time'} = $time;
            my $compare_type = $self->{statefile_cache}->get(name => $instance . '_type');
            my $compare_time = $self->{statefile_cache}->get(name => $instance . '_time');
            next if (defined($compare_type) && defined($compare_time) && $type eq $compare_type && $time eq $compare_time);
        }
        
        $num_alarms_checked++;
        
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' && $type !~ /$self->{option_results}->{filter_type}/);
        
        my ($days, $hours, $minutes, $seconds) = ($time / 100 / 86400, $time / 100 % 86400 / 3600, $time / 100 % 86400 % 3600 / 60, $time / 100 % 86400 % 3600 % 60);
        $num_errors++;
        $self->{output}->output_add(long_msg => sprintf("%d day(s), %d:%d:%d : %s", 
                                                         $days, $hours, $minutes, $seconds,
                                                         $type
                                                         )
                                    );
        
        
    }
    
    $self->{output}->output_add(long_msg => sprintf("Number of message checked: %s", $num_alarms_checked));
    if ($num_errors != 0) {
        # Message problem
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d problem detected (use verbose for more details)", $num_errors)
                                    );
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => $datas);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check alarms (XUPS-MIB).

=over 8

=item B<--warning>

Use warning return instead 'critical'.

=item B<--memory>

Only check new alarms.

=item B<--filter-type>

Filter on type. (can be a regexp)
Default: ^(?!(UtilityPowerRestored|NoticeCondition|ReturnFromLowBattery|AlarmEntryAdded|AlarmEntryRemoved))

=back

=cut
    