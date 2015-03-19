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

package network::juniper::common::junos::mode::components::fru;

use strict;
use warnings;

my %map_fru_offline = (
    1 => 'unknown', 2 => 'none', 3 => 'error', 4 => 'noPower', 5 => 'configPowerOff', 6 => 'configHoldInReset', 
    7 => 'cliCommand', 8 => 'buttonPress', 9 => 'cliRestart', 10 => 'overtempShutdown', 11 => 'masterClockDown', 
    12 => 'singleSfmModeChange', 13 => 'packetSchedulingModeChange', 14 => 'physicalRemoval', 15 => 'unresponsiveRestart', 
    16 => 'sonetClockAbsent', 17 => 'rddPowerOff', 18 => 'majorErrors', 19 => 'minorErrors', 20 => 'lccHardRestart', 
    21 => 'lccVersionMismatch', 22 => 'powerCycle', 23 => 'reconnect', 24 => 'overvoltage', 25 => 'pfeVersionMismatch', 
    26 => 'febRddCfgChange', 27 => 'fpcMisconfig', 28 => 'fruReconnectFail', 29 => 'fruFwddReset', 30 => 'fruFebSwitch', 
    31 => 'fruFebOffline', 32 => 'fruInServSoftUpgradeError', 33 => 'fruChasdPowerRatingExceed', 34 => 'fruConfigOffline', 
    35 => 'fruServiceRestartRequest', 36 => 'spuResetRequest', 37 => 'spuFlowdDown', 38 => 'spuSpi4Down', 39 => 'spuWatchdogTimeout', 
    40 => 'spuCoreDump', 41 => 'fpgaSpi4LinkDown', 42 => 'i3Spi4LinkDown', 43 => 'cppDisconnect', 44 => 'cpuNotBoot', 
    45 => 'spuCoreDumpComplete', 46 => 'rstOnSpcSpuFailure', 47 => 'softRstOnSpcSpuFailure', 48 => 'hwAuthenticationFailure', 
    49 => 'reconnectFpcFail', 50 => 'fpcAppFailed', 51 => 'fpcKernelCrash', 52 => 'spuFlowdDownNoCore', 53 => 'spuFlowdCoreDumpIncomplete',
    54 => 'spuFlowdCoreDumpComplete', 55 => 'spuIdpdDownNoCore', 56 => 'spuIdpdCoreDumpIncomplete', 57 => 'spuIdpdCoreDumpComplete', 
    58 => 'spuCoreDumpIncomplete', 59 => 'spuIdpdDown', 60 => 'fruPfeReset', 61 => 'fruReconnectNotReady', 62 => 'fruSfLinkDown', 
    63 => 'fruFabricDown', 64 => 'fruAntiCounterfeitRetry', 65 => 'fruFPCChassisClusterDisable', 66 => 'spuFipsError', 
    67 => 'fruFPCFabricDownOffline', 68 => 'febCfgChange', 69 => 'routeLocalizationRoleChange', 70 => 'fruFpcUnsupported', 
    71 => 'psdVersionMismatch', 72 => 'fruResetThresholdExceeded', 73 => 'picBounce', 74 => 'badVoltage', 75 => 'fruFPCReducedFabricBW', 
    76 => 'fruAutoheal', 77 => 'builtinPicBounce', 78 => 'fruFabricDegraded', 79 => 'fruFPCFabricDegradedOffline', 80 => 'fruUnsupportedSlot', 
    81 => 'fruRouteLocalizationMisCfg', 82 => 'fruTypeConfigMismatch', 83 => 'lccModeChanged', 84 => 'hwFault', 85 => 'fruPICOfflineOnEccErrors',
    86 => 'fruFpcIncompatible', 87 => 'fruFpcFanTrayPEMIncompatible', 88 => 'fruUnsupportedFirmware', 
    89 => 'openflowConfigChange', 90 => 'fruFpcScbIncompatible', 91 => 'fruReUnresponsive' 
);
my %map_fru_type = (
    1 => 'other', 2 => 'clockGenerator', 3 => 'flexiblePicConcentrator', 4 => 'switchingAndForwardingModule', 5 => 'controlBoard', 
    6 => 'routingEngine', 7 => 'powerEntryModule', 8 => 'frontPanelModule', 9 => 'switchInterfaceBoard', 10 => 'processorMezzanineBoardForSIB', 
    11 => 'portInterfaceCard', 12 => 'craftInterfacePanel', 13 => 'fan', 14 => 'lineCardChassis', 15 => 'forwardingEngineBoard', 
    16 => 'protectedSystemDomain', 17 => 'powerDistributionUnit', 18 => 'powerSupplyModule', 19 => 'switchFabricBoard', 20 => 'adapterCard' 
);

my %map_fru_states = (
    1 => 'unknown', 
    2 => 'empty', 
    3 => 'present', 
    4 => 'ready',
    5 => 'announce online',
    6 => 'online',
    7 => 'announce offline',
    8 => 'offline',
    9 => 'diagnostic',
    10 => 'standby',
);

# In MIB 'mib-jnx-chassis'
my $mapping = {
    jnxFruName => { oid => '.1.3.6.1.4.1.2636.3.1.15.1.5' },
    jnxFruType => { oid => '.1.3.6.1.4.1.2636.3.1.15.1.6', map => \%map_fru_type },
    jnxFruState => { oid => '.1.3.6.1.4.1.2636.3.1.15.1.8', map => \%map_fru_states },
    jnxFruTemp => { oid => '.1.3.6.1.4.1.2636.3.1.15.1.9' },
    jnxFruOfflineReason => { oid => '.1.3.6.1.4.1.2636.3.1.15.1.10', map => \%map_fru_offline },
};
my $oid_jnxFruEntry = '.1.3.6.1.4.1.2636.3.1.15.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_jnxFruEntry, start => $mapping->{jnxFruName}->{oid}, end => $mapping->{jnxFruOfflineReason}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking frus");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fru'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_jnxFruEntry}})) {
        next if ($oid !~ /^$mapping->{jnxFruName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_jnxFruEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'fru', instance => $instance));
        next if ($result->{jnxFruState} =~ /empty/i && 
                 $self->absent_problem(section => 'fru', instance => $instance));
        $self->{components}->{fru}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Fru '%s' state is %s [instance: %s, type: %s, offline reason: %s]", 
                                    $result->{jnxFruName}, $result->{jnxFruState}, 
                                    $instance, $result->{jnxFruType}, $result->{jnxFruOfflineReason}));
        my $exit = $self->get_severity(section => 'fru', value => $result->{jnxFruState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fru '%s' state is %s [offline reason: %s]", $result->{jnxFruName}, $result->{jnxFruState},
                                                             $result->{jnxFruOfflineReason}));
        }
        
        if (defined($result->{jnxFruTemp}) && $result->{jnxFruTemp} != 0) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fru-temperature', instance => $instance, value => $result->{jnxFruTemp});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Fru '%s' temperature is %s degree centigrade", $result->{jnxFruName}, $result->{jnxFruTemp}));
            }
            $self->{output}->perfdata_add(label => "temp_" . $result->{jnxFruName}, unit => 'C',
                                          value => $result->{jnxFruTemp},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;