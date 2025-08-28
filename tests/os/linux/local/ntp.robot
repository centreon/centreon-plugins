*** Settings ***
Documentation       Linux Local ntp

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin


*** Test Cases ***
ntp auto ${tc}
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ntp
    ...    --command-path=${CURDIR}${/}ntp_all_bin
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                      expected_result    --
            ...      1     ${EMPTY}                                                           OK: Number of ntp peers: 5 - All peers are ok | 'peers.detected.count'=5;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;;;0; '0.pool.ntp.org#peer.stratum.count'=1;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      2     --filter-name='^[1-3]' --exclude-name='^2'                         OK: Number of ntp peers: 2 - All peers are ok | 'peers.detected.count'=2;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      3     --filter-state='.*configured.*' --exclude-state='.*fallback.*'     OK: Number of ntp peers: 2 - All peers are ok | 'peers.detected.count'=2;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      4     --critical-peers='10:'                                             CRITICAL: Number of ntp peers: 5 | 'peers.detected.count'=5;;10:;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;;;0; '0.pool.ntp.org#peer.stratum.count'=1;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      5     --warning-offset='3:'                                              WARNING: Peer '0.pool.ntp.org' offset: 2.957 ms | 'peers.detected.count'=5;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;3:;;0; '0.pool.ntp.org#peer.stratum.count'=1;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      6     --critical-stratum='1:'                                            CRITICAL: Peer '1.pool.ntp.org' stratum: 0 - Peer '2.pool.ntp.org' stratum: 0 - Peer '3.pool.ntp.org' stratum: 0 - Peer '4.pool.ntp.org' stratum: 0 | 'peers.detected.count'=5;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;1:;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;;;0; '0.pool.ntp.org#peer.stratum.count'=1;;1:;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;1:;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;1:;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;1:;0;
            ...      7     --ntp-mode=auto                                                    OK: Number of ntp peers: 5 - All peers are ok | 'peers.detected.count'=5;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;;;0; '0.pool.ntp.org#peer.stratum.count'=1;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;;0;
            ...      8     --ntp-mode=chronyc                                                 OK: Number of ntp peers: 8 - All peers are ok | 'peers.detected.count'=8;;;0; '185.125.190.56#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.56#peer.stratum.count'=2;;;0; '185.125.190.57#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.57#peer.stratum.count'=2;;;0; '188.125.64.7#peer.time.offset.milliseconds'=60ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2606:4700:f1::123#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::123#peer.stratum.count'=3;;;0; '2620:2d:4000:1::3f#peer.time.offset.milliseconds'=14ms;;;0; '2620:2d:4000:1::3f#peer.stratum.count'=2;;;0; '88.81.100.130#peer.time.offset.milliseconds'=22ms;;;0; '88.81.100.130#peer.stratum.count'=1;;;0; '91.189.91.157#peer.time.offset.milliseconds'=81ms;;;0; '91.189.91.157#peer.stratum.count'=2;;;0;
            ...      9     --ntp-mode=ntpq                                                    OK: Number of ntp peers: 7 - All peers are ok | 'peers.detected.count'=7;;;0; '162.159.200.1#peer.time.offset.milliseconds'=+1.681ms;;;0; '162.159.200.1#peer.stratum.count'=3;;;0; '162.159.200.123#peer.time.offset.milliseconds'=+18.266ms;;;0; '162.159.200.123#peer.stratum.count'=3;;;0; '188.125.64.7#peer.time.offset.milliseconds'=-10.248ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '193.1.12.167#peer.time.offset.milliseconds'=-20.845ms;;;0; '193.1.12.167#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=-0.426ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2a00:1288:110:f#peer.time.offset.milliseconds'=-0.069ms;;;0; '2a00:1288:110:f#peer.stratum.count'=2;;;0;
            ...     10     --ntp-mode=all                                                     OK: Number of ntp peers: 20 - All peers are ok | 'peers.detected.count'=20;;;0; '1.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '1.pool.ntp.org#peer.stratum.count'=0;;;0; '162.159.200.1#peer.time.offset.milliseconds'=+1.681ms;;;0; '162.159.200.1#peer.stratum.count'=3;;;0; '162.159.200.123#peer.time.offset.milliseconds'=+18.266ms;;;0; '162.159.200.123#peer.stratum.count'=3;;;0; '185.125.190.56#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.56#peer.stratum.count'=2;;;0; '185.125.190.57#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.57#peer.stratum.count'=2;;;0; '188.125.64.7#peer.time.offset.milliseconds'=-10.248ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '193.1.12.167#peer.time.offset.milliseconds'=-20.845ms;;;0; '193.1.12.167#peer.stratum.count'=2;;;0; '0.pool.ntp.org#peer.time.offset.milliseconds'=2.957ms;;;0; '0.pool.ntp.org#peer.stratum.count'=1;;;0; '2.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '2.pool.ntp.org#peer.stratum.count'=0;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=-0.426ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2606:4700:f1::123#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::123#peer.stratum.count'=3;;;0; '2620:2d:4000:1::3f#peer.time.offset.milliseconds'=14ms;;;0; '2620:2d:4000:1::3f#peer.stratum.count'=2;;;0; '2a00:1288:110:f#peer.time.offset.milliseconds'=-0.069ms;;;0; '2a00:1288:110:f#peer.stratum.count'=2;;;0; '3.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '3.pool.ntp.org#peer.stratum.count'=0;;;0; '4.pool.ntp.org#peer.time.offset.milliseconds'=0ms;;;0; '4.pool.ntp.org#peer.stratum.count'=0;;;0; '88.81.100.130#peer.time.offset.milliseconds'=22ms;;;0; '88.81.100.130#peer.stratum.count'=1;;;0; '91.189.91.157#peer.time.offset.milliseconds'=81ms;;;0; '91.189.91.157#peer.stratum.count'=2;;;0;


ntp chronyc ${tc}
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ntp
    ...    --command-path=${CURDIR}${/}ntp_chrony_bin
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                      expected_result    --
            ...      0     ${EMPTY}                                                           OK: Number of ntp peers: 8 - All peers are ok | 'peers.detected.count'=8;;;0; '185.125.190.56#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.56#peer.stratum.count'=2;;;0; '185.125.190.57#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.57#peer.stratum.count'=2;;;0; '188.125.64.7#peer.time.offset.milliseconds'=60ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2606:4700:f1::123#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::123#peer.stratum.count'=3;;;0; '2620:2d:4000:1::3f#peer.time.offset.milliseconds'=14ms;;;0; '2620:2d:4000:1::3f#peer.stratum.count'=2;;;0; '88.81.100.130#peer.time.offset.milliseconds'=22ms;;;0; '88.81.100.130#peer.stratum.count'=1;;;0; '91.189.91.157#peer.time.offset.milliseconds'=81ms;;;0; '91.189.91.157#peer.stratum.count'=2;;;0;
            ...      1     --ntp-mode=chronyc                                                 OK: Number of ntp peers: 8 - All peers are ok | 'peers.detected.count'=8;;;0; '185.125.190.56#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.56#peer.stratum.count'=2;;;0; '185.125.190.57#peer.time.offset.milliseconds'=25ms;;;0; '185.125.190.57#peer.stratum.count'=2;;;0; '188.125.64.7#peer.time.offset.milliseconds'=60ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2606:4700:f1::123#peer.time.offset.milliseconds'=18ms;;;0; '2606:4700:f1::123#peer.stratum.count'=3;;;0; '2620:2d:4000:1::3f#peer.time.offset.milliseconds'=14ms;;;0; '2620:2d:4000:1::3f#peer.stratum.count'=2;;;0; '88.81.100.130#peer.time.offset.milliseconds'=22ms;;;0; '88.81.100.130#peer.stratum.count'=1;;;0; '91.189.91.157#peer.time.offset.milliseconds'=81ms;;;0; '91.189.91.157#peer.stratum.count'=2;;;0;



ntp ntpq ${tc}
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ntp
    ...    --command-path=${CURDIR}${/}ntp_ntpq_bin
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                      expected_result    --
            ...      0     ${EMPTY}                                                           OK: Number of ntp peers: 7 - All peers are ok | 'peers.detected.count'=7;;;0; '162.159.200.1#peer.time.offset.milliseconds'=+1.681ms;;;0; '162.159.200.1#peer.stratum.count'=3;;;0; '162.159.200.123#peer.time.offset.milliseconds'=+18.266ms;;;0; '162.159.200.123#peer.stratum.count'=3;;;0; '188.125.64.7#peer.time.offset.milliseconds'=-10.248ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '193.1.12.167#peer.time.offset.milliseconds'=-20.845ms;;;0; '193.1.12.167#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=-0.426ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2a00:1288:110:f#peer.time.offset.milliseconds'=-0.069ms;;;0; '2a00:1288:110:f#peer.stratum.count'=2;;;0;
            ...      1     --ntp-mode=ntpq                                                    OK: Number of ntp peers: 7 - All peers are ok | 'peers.detected.count'=7;;;0; '162.159.200.1#peer.time.offset.milliseconds'=+1.681ms;;;0; '162.159.200.1#peer.stratum.count'=3;;;0; '162.159.200.123#peer.time.offset.milliseconds'=+18.266ms;;;0; '162.159.200.123#peer.stratum.count'=3;;;0; '188.125.64.7#peer.time.offset.milliseconds'=-10.248ms;;;0; '188.125.64.7#peer.stratum.count'=2;;;0; '193.1.12.167#peer.time.offset.milliseconds'=-20.845ms;;;0; '193.1.12.167#peer.stratum.count'=2;;;0; '2606:4700:f1::1#peer.time.offset.milliseconds'=-0.426ms;;;0; '2606:4700:f1::1#peer.stratum.count'=3;;;0; '2a00:1288:110:f#peer.time.offset.milliseconds'=-0.069ms;;;0; '2a00:1288:110:f#peer.stratum.count'=2;;;0;
