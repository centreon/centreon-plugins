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

package network::adva::fsp150::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'alarm %s [severity: %s] [type: %s] [object: %s] [description: %s] %s',
        $self->{result_values}->{label},
        $self->{result_values}->{severity},
        $self->{result_values}->{type},
        $self->{result_values}->{object},
        $self->{result_values}->{description},
        $self->{result_values}->{generation_time}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'severity' }, { name => 'type' },
                    { name => 'label'}, { name => 'since' },
                    { name => 'object' }, { name => 'description' },
                    { name => 'generation_time' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{severity} eq "serviceAffecting"' },
        'memory'              => { name => 'memory' },
        'timezone:s'          => { name => 'timezone' }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'DateTime',
        error_msg => "Cannot load module 'DateTime'."
    );
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

my $map_type = {
    0 => 'none', 1 => 'acoopr', 2 => 'hwinitedsysboot', 3 => 'userinitednemireboot', 4 => 'userinitedsysboot', 
    5 => 'userinitedsysbootdefaultdb', 6 => 'userinitedsysbootdbrestore ', 7 => 'userinitedsysrebootswact', 
    8 => 'sysrecoveryfailed', 9 => 'primntpsvrFailed', 10 => 'bckupntpsvrFailed', 11 => 'swdl-ftip', 12 => 'swdl-ftfail', 
    13 => 'swdl-ftpass', 14 => 'swdl-instip', 15 => 'swdl-instfail', 16 => 'swdl-instpass', 17 => 'swdl-actip', 
    18 => 'swdl-actfail', 19 => 'swdl-actpass', 20 => 'swdl-valip', 21 => 'swdl-valfail', 22 => 'swdl-valpass', 
    23 => 'db-ftip', 24 => 'db-ftfail', 25 => 'db-ftpass', 26 => 'ctneqpt', 27 => 'eqptflt', 28 => 'forced', 
    29 => 'lockout', 30 => 'manualswitch', 31 => 'wkswtopr', 32 => 'wkswbk', 33 => 'mismatch', 34 => 'psu1fail',
    35 => 'psu2fail', 36 => 'eqptremoved', 37 => 'autonegunknown', 38 => 'dyinggasp', 39 => 'efmfail', 40 => 'efmrce', 
    41 => 'efmrld', 42 => 'efmrls', 43 => 'lnkdeactivated', 44 => 'lnkdownunisolated', 45 => 'lnkdowncablefault', 
    46 => 'lnkdowncableremoved', 47 => 'lnkdownautonegfailed', 48 => 'lnkdownlpbkfault', 49 => 'lnkdowncabletestfault', 
    50 => 'lnkdown', 51 => 'rfi', 52 => 'rxjabber', 53 => 'sfpmismatch', 54 => 'sfpremoved', 55 => 'sfptxfault', 56 => 'sfpinserted', 
    57 => 'fan-a', 58 => 'fan-b', 59 => 'overtemp', 60 => 'undertemp', 61 => 'overvoltage', 62 => 'undervoltage', 
    63 => 'shelfrmvd', 64 => 'rmtefmlpbkfail', 65 => 'inpwrflt', 66 => 'crossconnectccm', 67 => 'erroneousccm', 
    68 => 'someremotemepccm', 69 => 'somemacstatus', 70 => 'somerdi', 71 => 'ais', 72 => 'syncref', 73 => 'esmcfail', 
    74 => 'qlmismatch', 75 => 'freqoff', 76 => 'los', 77 => 'lof', 78 => 'qlsqlch', 79 => 'frngsync', 80 => 'fstsync', 
    81 => 'hldovrsync', 82 => 'losloc', 83 => 'wtr', 84 => 'allsyncref', 85 => 'qlinvalid', 86 => 'snmpdghostunresolved',
    87 => 'snmpdghostresourcesbusy', 88 => 'bwexceedednegspeed', 89 => 'shaperbtd', 90 => 'sfpnonqualified', 
    91 => 'avghldovrfrqnotrdy', 92 => 'lnkdownmasterslavecfg', 93 => 'pwrnoinputunitfault', 94 => 'ipaddrconflict', 
    95 => 'nomoreresources', 96 => 'syncreflck', 97 => 'syncreffrc', 98 => 'syncrefman', 99 => 'syncrefwtr', 
    100 => 'syncrefsw', 101 => 'lcpfail', 102 => 'lcploopback', 103 => 'authservernotreachable', 104 => 'excessiveinterrupts', 
    105 => 'dbdowngradeip', 106 => 'testalarm', 107 => 'gen-filexfer-ip', 108 => 'gen-filexfer-fail', 109 => 'gen-filexfer-pass', 
    110 => 'gen-oper-ip', 111 => 'gen-oper-fail', 112 => 'gen-oper-pass', 113 => 'trafficfail', 114 => 'clockfail', 
    115 => 'rdncyswitchover', 116 => 'rdncyswvermismatch', 117 => 'rdncyoutofsync', 118 => 'rdncylockout', 119 => 'rdncymaintenance', 
    120 => 'xfptxfault', 121 => 'xfpmismatch', 122 => 'xfpnonqualified', 123 => 'xfpremoved', 124 => 'xfpinserted', 
    125 => 'lagmbrfail', 126 => 'swdl-proip', 127 => 'swdl-propass', 128 => 'swdl-profail', 129 => 'db-proip', 
    130 => 'db-propass', 131 => 'db-profail', 132 => 'swdl-rvtip', 133 => 'swdl-rvtpass', 134 => 'swdl-rvtfail', 
    135 => 'db-corruption', 136 => 'bpmismatch', 137 => 'popr-oovar', 138 => 'popr-oorange', 139 => 'popr-genfail', 
    140 => 'popr-sfpnqual', 141 => 'popr-rta', 142 => 'modemmea', 143 => 'modemnonqualified', 144 => 'modemremoved', 
    145 => 'nosimcard', 146 => 'env-genfail', 147 => 'env-misc', 148 => 'env-batterydischarge', 149 => 'env-batteryfail', 
    150 => 'env-coolingfanfail', 151 => 'env-enginefail', 152 => 'env-fusefail', 153 => 'env-hightemp', 154 => 'env-intrusion', 
    155 => 'env-lowbatteryvoltage', 156 => 'env-lowtemp', 157 => 'env-opendoor', 158 => 'env-powerfail', 159 => 'intctneqpt', 
    160 => 'syncnotready', 161 => 'vcgfail', 162 => 'loa', 163 => 'plct', 164 => 'tlct', 165 => 'plcr', 166 => 'tlcr', 167 => 'sqnc', 
    168 => 'ais-l', 169 => 'rfi-l', 170 => 'rei-l', 171 => 'exc-l', 172 => 'deg-l', 173 => 'tim-s', 174 => 'ais-p', 175 => 'lop-p', 
    176 => 'tim-p', 177 => 'uneq-p', 178 => 'plm-p', 179 => 'lom-p', 180 => 'exc-p', 181 => 'deg-p', 182 => 'rei-p', 183 => 'rfi-p', 
    184 => 'lcascrc', 185 => 'sqm', 186 => 'lom', 187 => 'gidmismatch', 188 => 'mnd', 189 => 'ais-v', 190 => 'lop-v', 191 => 'tim-v', 
    192 => 'uneq-v', 193 => 'plm-v', 194 => 'exc-v', 195 => 'deg-v', 196 => 'rei-v', 197 => 'rfi-v', 198 => 'rmtinitlpbk', 199 => 'rai', 
    200 => 'rei', 201 => 'idle', 202 => 'csf', 203 => 'gfplfd', 204 => 'gfpuplmismatch', 205 => 'gfpexhmismatch', 206 => 'vcat-lom', 
    207 => 'fragileecc', 208 => 'elmi-seqnummismatch', 209 => 'elmi-notoper', 210 => 'pw-rlofs', 211 => 'pw-lof', 212 => 'pw-latefrm',
    213 => 'pw-jbovrn', 214 => 'allsoocsfailed', 215 => 'tsholdoverfrqnotready', 216 => 'tsfreerun', 217 => 'tsholdover', 218 => 'ptsflossofsync', 
    219 => 'ptsflossofannounce', 220 => 'ptsfunusable', 221 => 'unresolvedsatop', 222 => 'rdi-v', 223 => 'autonegBypass', 224 => 'forcedOffline', 
    225 => 'hwcfginconsistent', 226 => 'sjmtiemaskcross', 227 => 'sjoffsetfail', 228 => 'sjnotimelock', 229 => 'sjnofreqlock', 230 => 'sjmtiemargincross', 
    231 => 'sjtestreferencefail', 232 => 'sjtestsourcefail', 233 => 'sjtestnotimestamp', 234 => 'sjtestnomessages', 235 => 'gpsantennafail', 
    236 => 'ampNoPeer', 237 => 'ampProvFail', 238 => 'ampCfgFail', 239 => 'ltpFailure', 240 => 'ltpInprogress', 241 => 'pse-power-threshold-exceeded', 
    242 => 'pse-power-fail', 243 => 'pse-poweroff-overcurrent', 244 => 'pse-poweroff-overvoltage', 245 => 'pse-poweroff-overload', 
    246 => 'pse-poweroff-overtemp', 247 => 'pse-poweroff-short', 248 => 'erpFoPPM', 249 => 'erpFoPTO', 250 => 'erpBlockPort0RPL', 251 => 'erpBlockPort0SF', 
    252 => 'erpBlockPort0MS', 253 => 'erpBlockPort0FS', 254 => 'erpBlockPort0WTR', 255 => 'erpBlockPort1RPL', 256 => 'erpBlockPort1SF', 
    257 => 'erpBlockPort1MS', 258 => 'erpBlockPort1FS', 259 => 'erpBlockPort1WTR', 260 => 'ipv6addr-conflict', 261 => 'macAddrlearntblFull', 
    262 => 'timeClockNotLocked', 263 => 'timeNotTraceAble', 264 => 'timeFreqNotTraceAble', 265 => 'timeHoldOver', 266 => 'timeFreqLock', 
    267 => 'timeRefLock', 268 => 'timeRefUnavailable', 269 => 'timeRefDegraded', 270 => 'timeRefFrc', 271 => 'tsTimeFrun', 272 => 'tsTimeHoldOver', 
    273 => 'timeRefUnavailableWTR', 274 => 'timeRefDegradedWTR', 275 => 'rmtInitSat', 276 => 'lldpRemoteTblChg', 277 => 'soocLck', 278 => 'ampProvSuccess', 
    279 => 'ampCfgSuccess', 280 => 'soocSW', 281 => 'soocWTR', 282 => 'sjtealert', 283 => 'dataExportFtpFail', 284 => 'xfpWaveLengthMismatch', 
    285 => 'cpmrUpgrading', 286 => 'beaconLightFailure', 287 => 'manualSwitchClear', 288 => 'loopbackActive', 289 => 'loopbackRequest', 
    290 => 'trafficResourceLimitExceeded', 291 => 'oduAis', 292 => 'opuAis', 293 => 'otuAis', 294 => 'otnProtMsmtch', 295 => 'otnProtPrtclFail', 
    296 => 'oduBdi', 297 => 'otuBdi', 298 => 'lossCharSync', 299 => 'berHigh', 300 => 'laserFail', 301 => 'laserCurrentAbnormal', 302 => 'oduLock', 
    303 => 'autoShutdown', 304 => 'localFault', 305 => 'otuLof', 306 => 'otuLom', 307 => 'oduOci', 308 => 'opuPlm', 309 => 'oduSd', 310 => 'otuSd', 
    311 => 'opuSf', 312 => 'optPowerHighRx', 313 => 'optPowerLowRx', 314 => 'optPowerHighTx', 315 => 'optPowerLowTx', 316 => 'oduTim', 317 => 'otuTim', 
    318 => 'sjConstTeThrshld', 319 => 'sjInstTeThrshld', 320 => 'timeRefSW', 321 => 'aadcfailed', 322 => 'ptpfreqfrun', 323 => 'ptptimefrun', 
    324 => 'ptpfreqhldovr', 325 => 'ptptimehldovr', 326 => 'ptptimenottraceable', 327 => 'ptpfreqnottraceable', 328 => 'synctimeout', 329 => 'announcetimeout', 
    330 => 'delayresptimeout', 331 => 'multiplepeers', 332 => 'wrongdomain', 333 => 'nosatellitercv', 334 => 'trafficipifoutage', 335 => 'ptpportstatechanged',
    336 => 'physicalSelfLpbk', 337 => 'cfCardRWFail', 338 => 'maxexpectedslaves', 339 => 'external-alarm', 340 => 'maskcrossed', 341 => 'oof', 
    342 => 'signalfail', 343 => 'timenottai', 344 => 'perffuncfailure', 345 => 'ptpportnotoper', 346 => 'leapsecondexpected', 347 => 'keyExchangeFail', 
    348 => 'keyExchangeAuthPasswordMissing', 349 => 'secureRamCleared', 350 => 'noRouteResources', 351 => 'tamperSwitchOpen', 352 => 'bfdSessionDown', 
    353 => 'destinationUnresolved', 354 => 'sjmaxtethrshld', 355 => 'trafficArpTableFull', 357 => 'erpRingSegmentation(356), gpsrcvrfail', 
    358 => 'noActiveRoute', 359 => 'vxlanDMac2DIPTableFull', 360 => 'bwExceedLagMemberPortSpeed', 361 => 'greRemoteUnreachable', 362 => 'bweexceedsportspeed', 
    363 => 'servicediscarded', 364 => 'bmcaError', 365 => 'freeze', 366 => 'gpsFwUpgrade', 367 => 'storageWearout', 368 => 'pps-not-generated', 
    369 => 'min-sat-1-thrshld-crossed', 370 => 'min-sat-2-thrshld-crossed', 371 => 'gatewayNotReachable', 372 => 'pdop-mask-cross', 373 => 'nc-initInProgress', 
    374 => 'primaryNtpSvr-auth-failed', 375 => 'backupNtpSvr-auth-failed', 376 => 'clock-class-mismatch', 377 => 'hpg-switch-force', 378 => 'hpg-switch-lockout',
    379 => 'hpg-switch-to-3gpp-path', 380 => 'hpg-switch-to-fixed-path', 381 => 'bgp-linkdown', 382 => 'ospf-neighbour-lost', 383 => 'traffic-ndptable-full', 
    384 => 'dup-link-local-address', 385 => 'dup-unicast-address', 386 => 'ztp-failed', 387 => 'ztp-in-progress', 388 => 'nc-runningConfigLocked', 
    389 => 'pwrnoinput2', 390 => 'keyExchangeStopped', 391 => 'security-error', 392 => 'pppoe-connection-failed', 393 => 'no-ipv6route-resource', 
    394 => 'sfp-firmware-revision-mismatch', 395 => 'vrrp-new-master', 396 => 'nontpkeys', 397 => 'timesrcunavailable', 398 => 'syncsrcunavailable', 
    399 => 'local-cooling-fail', 400 => 'jamming', 401 => 'spoofing', 402 => 'httpsSslCertExpiryPending', 403 => 'httpsSslCertExpired', 404 => 'srgb-collision', 
    405 => 'sid-collision', 406 => 'sr-index-out-of-range'
};
my $map_severity = {
    0 => 'none', 1 => 'nonServiceAffecting', 2 => 'serviceAffecting'
};

my $oids = {
    cmSysAlmEntry => {
        oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1', label => 'sys',
        mapping => {
            type        => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1.2', map => $map_type }, # cmSysAlmType
            severity    => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1.3', map => $map_severity }, # cmSysAlmSrvEff
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1.4' }, # cmSysAlmTime
            description => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1.7' }, # cmSysAlmDescr
            object      => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.2.1.9' }, # cmSysAlmObjectName
        }
    },
    cmNetworkElementAlmEntry => {
        oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1', label => 'networkElement',
        mapping => {
            type        => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1.2', map => $map_type }, # cmNetworkElementAlmType
            severity    => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1.3', map => $map_severity }, # cmNetworkElementAlmSrvEff
            timestamp   => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1.4' }, # cmNetworkElementAlmTime
            description => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1.7' }, # cmNetworkElementAlmDescr
            object      => { oid => '.1.3.6.1.4.1.2544.1.12.6.1.4.1.9' }, # cmNetworkElementAlmObjectName
        }
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $get_oids = [];
    foreach (keys %$oids) {
        push @$get_oids, {
            oid => $oids->{$_}->{oid},
            start => $oids->{$_}->{mapping}->{type}->{oid},
            end => $oids->{$_}->{mapping}->{object}->{oid}
        };
    }
    my $snmp_result = $options{snmp}->get_multiple_table(oids => $get_oids);

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_adva_fsp150_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach (keys %$oids) {
        my $branch_oid = $oids->{$_}->{oid};
        next if (!defined($snmp_result->{$branch_oid}));
        
        foreach my $oid (keys %{$snmp_result->{$branch_oid}}) {
            next if ($oid !~ /^$oids->{$_}->{mapping}->{severity}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $options{snmp}->map_instance(mapping => $oids->{$_}->{mapping}, results => $snmp_result->{$branch_oid}, instance => $instance);

            my @date = unpack 'n C6 a C2', $result->{timestamp};
            my $timezone = $self->{option_results}->{timezone};
            if (defined($date[7])) {
                $timezone = sprintf("%s%02d%02d", $date[7], $date[8], $date[9]);
            }

            my $tz = centreon::plugins::misc::set_timezone(name => $timezone);
            my $dt = DateTime->new(
                year => $date[0], month => $date[1], day => $date[2], hour => $date[3], minute => $date[4], second => $date[5],
                %$tz
            );

            next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $dt->epoch);

            my $diff_time = $current_time - $dt->epoch;

            $self->{alarms}->{global}->{alarm}->{$i} = {
                since => $diff_time,
                generation_time => centreon::plugins::misc::change_seconds(value => $diff_time),
                label => $oids->{$_}->{label},
                %$result
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

Set warning threshold for status.
Can used special variables like: %{description}, %{object}, %{severity}, %{type}, %{label}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '%{severity} eq "serviceAffecting"').
Can used special variables like: {description}, %{object}, %{severity}, %{type}, %{label}, %{since}

=item B<--timezone>

Timezone options (the date from the equipment overload that option). Default is 'GMT'.

=item B<--memory>

Only check new alarms.

=back

=cut
