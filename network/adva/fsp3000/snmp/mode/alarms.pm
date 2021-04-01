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

package network::adva::fsp3000::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("alarm %s [severity: %s] [type: %s] %s", $self->{result_values}->{label}, $self->{result_values}->{severity},
        $self->{result_values}->{type}, $self->{result_values}->{generation_time});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{severity} = $options{new_datas}->{$self->{instance} . '_severity'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    $self->{result_values}->{generation_time} = $options{new_datas}->{$self->{instance} . '_generation_time'};
    $self->{result_values}->{label} = $options{new_datas}->{$self->{instance} . '_label'};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { label => 'alerts', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'severity' }, { name => 'type' }, { name => 'label'}, { name => 'since' }, { name => 'generation_time' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning-status:s"    => { name => 'warning_status', default => '%{severity} =~ /warning|minor/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{severity} =~ /critical|major/i' },
                                  "memory"              => { name => 'memory' },
                                  "timezone:s"          => { name => 'timezone' },
                                });
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'DateTime',
                                           error_msg => "Cannot load module 'DateTime'.");
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
    
    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

my %map_type = (
    0 => 'undefined', 5 => 'terminalLoopback', 6 => 'oosDisabled', 7 => 'oosManagement', 8 => 'oosMaintenance', 9 => 'oosAins', 10 => 'removed', 
    11 => 'lossOfSignal', 12 => 'optInputPwrReceivedTooLow', 13 => 'optInputPwrReceivedTooHigh', 14 => 'laserTemperatureTooHigh', 15 => 'laserTemperatureTooLow', 16 => 'optOutputPowerTransTooLow', 17 => 'optOutputPowerTransTooHigh', 
    18 => 'autoShutdownToHighTemp', 19 => 'autoShutdownToHighTxPwr', 20 => 'laserEndOfLife', 21 => 'serverSignalFailureVf', 22 => 'equalizationProgress', 
    23 => 'uPortFailure', 24 => 'autoShutdownBlock', 25 => 'autoPowerShutdown', 26 => 'confOutPowerTransTooHigh', 27 => 'confOutPowerTransTooLow', 
    28 => 'optSignalFailure', 29 => 'dsbdChannelPowerTooHigh', 30 => 'lossOfSignalCPort', 31 => 'lossOfSignalNPort', 32 => 'outputPowerFault', 
    33 => 'eqlzAdjust', 34 => 'ampFailure', 35 => 'eqptProvMismatch', 36 => 'backreflectionTooHigh', 48 => 'fiberConnLos', 49 => 'fiberConnOptFault', 
    50 => 'fiberConnInvalid', 51 => 'fiberConnMismatch', 52 => 'fiberConnCommError', 53 => 'fiberConnProtocolFailure', 54 => 'fiberConnDataFailure', 
    55 => 'fiberAttenuationHigh', 57 => 'laserBiasCurrAbnormal', 58 => 'fiberConnInvalidTx', 59 => 'fiberConnMismatchTx', 60 => 'fiberAttenuationHighTx', 
    61 => 'laserFailure', 62 => 'lossOfReceiverClockRecovery', 63 => 'fiberAttenuationCond', 64 => 'channelMismatch', 65 => 'alarmIndicationSignalLine', 
    66 => 'alarmIndicationSignalLowerOrderPath', 67 => 'alarmIndicationSignalOdu', 68 => 'alarmIndicationSignalOpu', 69 => 'alarmIndicationSignalOtu', 
    70 => 'alarmIndicationSignalHigherOrderPath', 71 => 'alarmIndicationSignalOduTcmA', 72 => 'alarmIndicationSignalOduTcmB', 73 => 'alarmIndicationSignalOduTcmC', 74 => 'virtualChannelAis', 
    75 => 'amplifierAbnormal', 76 => 'automaticPowerReduction', 77 => 'automaticPowerReductionForEyeSafety', 80 => 'apsConfigMismatch', 81 => 'apsProtocolFailure', 82 => 'aseLow', 
    83 => 'aseTableGenFailLow', 84 => 'aseTableGenFailHighBackreflection', 85 => 'aseTableGenFailOscMissing', 86 => 'aseTableGenFailPilot', 87 => 'aseTableGenFailSignalinput', 
    88 => 'aseTableNotAvailable', 89 => 'aseTableGenProgress', 90 => 'encryptionPortAuthPasswdMissing', 92 => 'backwardDefectIndicationOdu', 93 => 'backwardDefectIndicationOtu', 
    94 => 'backwardDefectIndicationOduTcmA', 95 => 'backwardDefectIndicationOduTcmB', 96 => 'backwardDefectIndicationOduTcmC', 97 => 'topologyDataCalculationInProgress', 99 => 'dispertionTunningCondition', 100 => 'lossOfCharSync', 
    101 => 'lossOfCharSyncFromFarEnd', 103 => 'encryptionPortEncryptionSwitchOffEnabled', 104 => 'encryptionModuleCryPasswdMissing', 107 => 'encryptionModuleSelfTestStarted', 108 => 'encryptionPortEncryptionSwitchedOff', 109 => 'opuClientSignalFail', 
    110 => 'databaseMismatch', 111 => 'databaseFailure', 112 => 'databaseNcuMismatch', 113 => 'dbReplicationIncompleted', 114 => 'databaseVersionMismatch', 115 => 'xfpDecisionThresSetFailed', 116 => 'duplexLinkFailure', 118 => 'singleFanFailure', 
    119 => 'multipleFanFailure', 120 => 'lossOfSignalTransmitter', 122 => 'farEndIpAddressUnknown', 123 => 'farEndCommFailure', 125 => 'backupForcedToHalt', 127 => 'facilityForcedOn', 128 => 'fwdAseTableFailPilot', 129 => 'fwdAseTableOnPilot', 
    131 => 'encryptionModuleFwpUpdateEnabled', 132 => 'fwpMismatchDownloadNotServiceAffecting', 133 => 'fwpMismatchDownloadServiceAffecting', 135 => 'gainTiltNotSettable', 136 => 'highBer', 137 => 'receiverOverloadProtection', 138 => 'hwInitializing', 139 => 'hwOprReachedHT', 
    140 => 'hwDegrade', 141 => 'hwFailure', 142 => 'switchtoProtectionInhibited', 143 => 'switchtoWorkingInhibited', 148 => 'encryptionPortKeyInitExchgMissed', 149 => 'encryptionPortMaxKeyExchgFailuresReachedIs', 150 => 'encryptionPortMaxKeyExchgFailuresReachedOos', 
    151 => 'encryptionPortKeyExchangedForced', 152 => 'laserOnDelay', 153 => 'lockedDefectOdu', 154 => 'lockedDefectOduTcmA', 155 => 'lockedDefectOduTcmB', 156 => 'lockedDefectOduTcmC', 157 => 'linkControlProtocolFailure', 158 => 'linkDown', 159 => 'autoShutdownSendingAisLine', 
    160 => 'autoShutdownSendingAisOdu', 161 => 'autoShutdownSendingAisOpu', 162 => 'clientFailForwarding', 163 => 'autoShutdownAls', 164 => 'autoAmpShutdown', 165 => 'autoShutdownAmpAps', 166 => 'aseTableBuild', 167 => 'autoShutdownOpuClientSignalFail', 168 => 'autoShutdownSendingEPC', 
    169 => 'autoShutdownSendingLckOdu', 170 => 'autoShutdownSendingOciOdu', 171 => 'autoShutdownLaserOffDueToErrFwd', 172 => 'autoShutdownTxRxLasersDueToHighTemp', 173 => 'localFault', 174 => 'localOscLevelAbnormal', 175 => 'lossOfGfpFrame', 176 => 'lossOfFrameMux', 177 => 'lossOfFrameOtu', 
    178 => 'lossOfFrame', 179 => 'lossOfFrameLossOfMultiFrameOdu', 180 => 'lossOfLane', 181 => 'lossofMultiframeLowerOrderPath', 182 => 'lossOfMultiFrameOtu', 183 => 'lossofMultiframeHigherOrderPath', 184 => 'lossOfPointerLowerOrderPath', 185 => 'lossOfPointerHigherOrderPath', 
    186 => 'losAttProgress', 187 => 'lossOsc', 188 => 'gfpLossOfClientSig', 189 => 'loopbackError', 190 => 'facilityLoopback', 191 => 'lossofTandemConnectionOduTcmA', 192 => 'lossofTandemConnectionOduTcmB', 193 => 'lossofTandemConnectionOduTcmC', 194 => 'mansw', 197 => 'equipmentNotAccepted', 198 => 'equipmentNotApproved', 199 => 'capabilityLevelMismatch', 
    200 => 'equipmentMismatch', 201 => 'equipmentNotSupportedByPhysicalLayer', 202 => 'meaSwRevision', 203 => 'mismatch', 204 => 'midstageFault', 205 => 'multiplexStructureIdentifierMismatchOPU', 206 => 'backupNotResponding', 207 => 'openConnectionIndicationOdu', 
    208 => 'openConnectionIndicationOduTcmA', 209 => 'openConnectionIndicationOduTcmB', 210 => 'openConnectionIndicationOduTcmC', 211 => 'oduTribMsiMismatch', 212 => 'transmitterDisabledOff', 213 => 'receiverDisabled', 214 => 'opmAbnormalCondition', 215 => 'faultOnOpm', 216 => 'thresOptPowerCtrlFailureHigh', 
    217 => 'thresOptPowerCtrlFailureLow', 218 => 'txPowerLimited', 219 => 'oscOpticalPowerControlFailHigh', 220 => 'oscOpticalPowerControlFailLow', 221 => 'oTDRMeasuringinProgress', 222 => 'encryptionModuleCryPasswdError', 223 => 'peerLink', 224 => 'pilotReceiveLevelHigh', 
    225 => 'lossOfPilotSignal', 226 => 'payloadMismatchGfp', 227 => 'payloadMismatchLowerOrderPath', 228 => 'payloadMismatchOPU', 229 => 'payloadMismatchHigherOrderPath', 230 => 'provPayloadMismatch', 231 => 'prbsLossOfSeqSynch', 232 => 'prbsRcvActivated', 233 => 'prbsTrmtActivated', 234 => 'protectionNotAvailable', 235 => 'powerSupplyUnitFailure', 236 => 'maxPowerConsProvModulesToHigh', 
    237 => 'maxPowerConsEquipModulesToHigh', 238 => 'powerMissing', 239 => 'remoteDefectIndicationLine', 240 => 'remoteDefectIndicationLowerOrderPath', 241 => 'remoteDefectIndicationHigherOrderPath', 243 => 'dcnCommunicationFail', 244 => 'ntpForSchedEqlzRequired', 245 => 'signalDegradeOlm', 246 => 'signalDegradeLine', 247 => 'signalDegradationonLinkVector', 
    248 => 'signalDegradeOdu', 249 => 'signalDegradeOtu', 250 => 'pcsSignalDegrade', 251 => 'signalDegradeScn', 252 => 'signalDegradeOduTcmA', 253 => 'signalDegradeOduTcmB', 254 => 'signalDegradeOduTcmC', 255 => 'encryptionModuleSelfTestFail', 256 => 'encryptionModuleSelfTestFailCritical', 
    257 => 'signalFailureOnLink', 258 => 'signalFailureonLinkVector', 259 => 'signalFailureOPU', 260 => 'serverSignalFailTx', 261 => 'facilityDataRateNotSupported', 263 => 'lossofSequenceLowerOrderPath', 264 => 'lossofSequenceHigherOrderPath', 265 => 'serverSignalFail', 266 => 'serverSignalFailureGfp', 
    267 => 'serverSignalFailureODU', 268 => 'serverSignalFailurePath', 269 => 'serverSignalFailureSectionRS', 272 => 'switchToDuplexInhibited', 274 => 'switchFailed', 276 => 'currentTooHigh', 277 => 'attOnReceiverFiberHigherThanMonitor', 278 => 'attOnReceiverFiberLowerThanMonitor', 279 => 'attOnTransmitterFiberHigherThanMonitor', 
    280 => 'attOnTransmitterFiberLowerThanMonitor', 281 => 'thres15MinExceededOduBbe', 283 => 'thres15MinExceededOtuBbe', 285 => 'thres15MinExceededOduTcmABbe', 287 => 'thres15MinExceededOduTcmBBbe', 289 => 'thres15MinExceededOduTcmCBbe', 291 => 'thres15MinExceededFecBERCE', 293 => 'brPwrRxTooHigh', 294 => 'chromaticDispersionTooHigh', 
    295 => 'chromaticDispersionTooLow', 296 => 'dispersionCompensationTooHigh', 297 => 'dispersionCompensationTooLow', 298 => 'thres15MinExceededFecCE', 300 => 'carrierFreqOffsetTooHigh', 301 => 'carrierFreqOffsetTooLow', 302 => 'thres15MinExceededSonetLineCV', 304 => 'thres15MinExceededPhysConvCV', 
    306 => 'thres15MinExceededSonetSectCV', 308 => 'thres15MinExceededPhysConvDE', 310 => 'differentialGroupDelayTooHigh', 311 => 'thres15MinExceededFecES', 313 => 'thres15MinExceededSonetLineES', 315 => 'thres15MinExceededOduES', 317 => 'thres15MinExceededOtuES', 
    319 => 'thres15MinExceededPhysConvES', 321 => 'thres15MinExceededSonetSectES', 323 => 'thres15MinExceededOduTcmAES', 325 => 'thres15MinExceededOduTcmBES', 327 => 'thres15MinExceededOduTcmCES', 329 => 'latencyTooHigh', 330 => 'latencyTooLow', 331 => 'laserBiasCurrentNormalizedtooHigh', 332 => 'localOscTemperatureTooHigh', 333 => 'localOscTemperatureTooLow', 
    334 => 'pumpLaser1TempTooHigh', 335 => 'pumpLaser1TempTooLow', 336 => 'pumpLaser2TempTooHigh', 337 => 'pumpLaser2TempTooLow', 338 => 'pumpLaser3TempTooHigh', 339 => 'pumpLaser3TempTooLow', 340 => 'pumpLaser4TempTooHigh', 341 => 'pumpLaser4TempTooLow', 342 => 'oscPwrTooHigh', 
    343 => 'oscPwrTooLow', 344 => 'ramanPumpPwrTooHigh', 345 => 'ramanPumpPwrTooLow', 346 => 'roundTripDelayTooHigh', 347 => 'roundTripDelayTooLow', 348 => 'thres15MinExceededSonetSectSEFS', 350 => 'thres15MinExceededFecSES', 352 => 'thres15MinExceededSonetLineSES', 
    354 => 'thres15MinExceededOduSES', 356 => 'thres15MinExceededOtuSES', 358 => 'thres15MinExceededSonetSectSES', 360 => 'thres15MinExceededOduTcmASES', 362 => 'thres15MinExceededOduTcmBSES', 364 => 'thres15MinExceededOduTcmCSES', 366 => 'logicalLanesSkewTooHigh', 
    367 => 'signalToNoiseRatioTooLow', 368 => 'subModuleTempTooHigh', 369 => 'temperatureTooHigh', 370 => 'temperatureTooLow', 371 => 'thres15MinExceededSonetLineUAS', 373 => 'thres15MinExceededOduUAS', 375 => 'thres15MinExceededOtuUAS', 
    377 => 'thres15MinExceededOduTcmAUAS', 379 => 'thres15MinExceededOduTcmBUAS', 381 => 'thres15MinExceededOduTcmCUAS', 383 => 'thres15MinExceededFecUBE', 385 => 'encryptionModuleTamperDetected', 386 => 'thermoElectricCoolerEndOfLife', 387 => 'alarmInputTIF', 389 => 'traceIdentifierMismatchOdu', 
    390 => 'traceIdentifierMismatchOtu', 391 => 'sectionTraceMismatch', 392 => 'traceIdentifierMismatchOduTcmA', 393 => 'traceIdentifierMismatchOduTcmB', 394 => 'traceIdentifierMismatchOduTcmC', 395 => 'turnupFailed', 396 => 'turnupCondition', 397 => 'unequippedLowerOrderPath', 398 => 'unequippedHigherOrderPath', 399 => 'voaControlFail', 400 => 'voltageOutOfRange', 401 => 'inputVoltageFailure', 402 => 'inputVoltageFailurePort1', 
    403 => 'inputVoltageFailurePort2', 406 => 'wtrTimerRunning', 407 => 'lossOfLaneOtu', 408 => 'lossOfTestSeqSynchOpu', 409 => 'lossOfMfiOpu', 410 => 'oosDisabledLckOduTrmt', 411 => 'configurationMismatch', 412 => 'oduAutoShutdownRxAIS', 413 => 'oduAutoShutdownTxAIS', 414 => 'oosDisabledLckOduRx', 420 => 'thres15MinExceededBbePcs', 
    422 => 'autoShutdownGAis', 423 => 'equipmentMismatchAllow', 424 => 'warmUp', 432 => 'networkPathRestricted', 434 => 'vfClientSignalFail', 435 => 'autoShutdownVfCSF', 439 => 'linkFailToPartner1', 440 => 'linkFailToPartner2', 441 => 'linkFailToPartner3', 442 => 'linkFailToPartner4', 443 => 'partnerUnavailable', 
    445 => 'partner1Deleted', 446 => 'partner2Deleted', 447 => 'partner3Deleted', 448 => 'partner4Deleted', 450 => 'thres15MinExceededPhysConvSE', 452 => 'thres15MinExceededPhysConvCVDE', 456 => 'autoShutdownSendingOciOduTx', 457 => 'acpLinkLoss', 458 => 'acpChannelUnAvail', 459 => 'acpPartnerUnassigned', 460 => 'acpPartnerDeleted', 461 => 'thres15MinExceededCrcErrorsRcv', 463 => 'thres15MinExceededCrcFramesEgress', 
    465 => 'autoServiceMismatch', 466 => 'batteryNoCharge', 469 => 'tagReceiveFail', 470 => 'tagReceiveFailMaxReached', 473 => 'internalEncryptionFail', 13006 => 'cfmRemoteDefectIndication', 13007 => 'cfmCcmMacStatus', 13008 => 'cfmCcmError', 13009 => 'cfmCcmLost', 13010 => 'cfmCcmXConn', 100005 => 'mepNotPresentL2', 100006 => 'priVidNotEqualExtVidL2', 100009 => 'sfCfmLevel0L2', 100010 => 'sfCfmLevel1L2', 100011 => 'sfCfmLevel2L2', 
    100012 => 'sfCfmLevel3L2', 100013 => 'sfCfmLevel4L2 ', 100014 => 'sfCfmLevel5L2', 100015 => 'sfCfmLevel6L2', 100016 => 'sfCfmLevel7L2', 120004 => 'messageLossSpeq', 120005 => 'oscFiberMissingSpeq', 120006 => 'optLowSpeq', 120007 => 'ppcOutOfRangeSpeq', 120008 => 'gainTooHighSpeq', 120009 => 'gainTooLowSpeq', 120010 => 'gainAdoptFailedSpeq', 120011 => 'processLockedOutSpeq', 120012 => 'ppcLimitExceededSpeq',
);
my %map_severity = (1 => 'indeterminate', 2 => 'critical', 3 => 'major', 4 => 'minor', 5 => 'warning', 6 => 'cleared', 7 => 'notReported');

my $oids = {
    alarmSysTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.1', label => 'sys',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.1.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.1.1.4' },
        }
    },
    alarmEqptTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.5', label => 'eqpt',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.5.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.5.1.4' },
        }
    },
    alarmFacilityTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.7', label => 'facility',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.7.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.7.1.4' },
        }
    },
    alarmTerminPointTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.9', label => 'terminpoint',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.9.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.9.1.4' },
        }
    },
    alarmExternalPortTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.11', label => 'externalport',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.11.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.11.1.4' },
        }
    },
    alarmDcnTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.16', label => 'dcn',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.16.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.16.1.4' },
        }
    },
    alarmEnvTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.20', label => 'env',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.20.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.20.1.4' },
        }
    },
    alarmContainerTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.24', label => 'container',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.24.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.24.1.4' },
        }
    },
    alarmOpticalMuxTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.28', label => 'opticalmux',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.28.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.28.1.4' },
        }
    },
    alarmShelfConnTable => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.34', label => 'shelfconn',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.32.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.32.1.4' },
        }
    },
    alarmNtpIPv4Table => {
        oid => '.1.3.6.1.4.1.2544.1.11.7.4.36', label => 'ntpipv4',
        mapping => {
            severity    => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.36.1.2', map => \%map_severity },
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.11.7.4.36.1.4' },
        }
    },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $get_oids = [];
    foreach (keys %$oids) {
        push @$get_oids, { oid => $oids->{$_}->{oid} };
    }
    my $snmp_result = $options{snmp}->get_multiple_table(oids => $get_oids);
    
    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_adva_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    
    foreach (keys %$oids) {
        my $branch_oid = $oids->{$_}->{oid};
        next if (!defined($snmp_result->{$branch_oid}));
        
        foreach my $oid (keys %{$snmp_result->{$branch_oid}}) {
            next if ($oid !~ /^$oids->{$_}->{mapping}->{severity}->{oid}\.(.*)\.(.*?)$/);
            my $instance = $1 . '.' . $2;
            my $type = defined($map_type{$2}) ? $map_type{$2} : 'unknown';
            my $result = $options{snmp}->map_instance(mapping => $oids->{$_}->{mapping}, results => $snmp_result->{$branch_oid}, instance => $instance);
            
            my @date = unpack 'n C6 a C2', $result->{timestamp};
            my $timezone = $self->{option_results}->{timezone};
            if (defined($date[7])) {
                $timezone = sprintf("%s%02d%02d", $date[7], $date[8], $date[9]);
            }

            my $tz = centreon::plugins::misc::set_timezone(name => $timezone);
            my $dt = DateTime->new(year => $date[0], month => $date[1], day => $date[2], hour => $date[3], minute => $date[4], second => $date[5],
                                   %$tz);

            next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $dt->epoch);

            my $diff_time = $current_time - $dt->epoch;

            $self->{alarms}->{global}->{alarm}->{$i} = { severity => $result->{severity}, 
                type => $type, since => $diff_time, 
                generation_time => centreon::plugins::misc::change_seconds(value => $diff_time),
                label => $oids->{$_}->{label}
            };
            $i++;
        }
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}
        
1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{severity} =~ /warning|minor/i')
Can used special variables like: %{severity}, %{type}, %{label}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} =~ /critical|major/i').
Can used special variables like: %{severity}, %{type}, %{label}, %{since}

=item B<--timezone>

Timezone options (the date from the equipment overload that option). Default is 'GMT'.

=item B<--memory>

Only check new alarms.

=back

=cut
