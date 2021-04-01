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
    