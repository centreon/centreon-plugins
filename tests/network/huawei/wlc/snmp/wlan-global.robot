*** Settings ***
Documentation       Check global WLAN access point count and user associated and authenticated.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
wlan-global ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=wlan-global
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                       expected_result    --
            ...      1     --verbose                                                                                           OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100 
            ...      2     --warning-total --critical-total                                                                    OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      3     --warning-normal --critical-normal                                                                  OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      4     --warning-normal-prct --critical-normal-prct                                                        OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      5     --warning-fault --critical-fault                                                                    OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      6     --warning-fault-prct --critical-fault-prct                                                          OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      7     --warning-current-user --critical-current-user                                                      OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      8     --warning-current-auth-user --critical-current-auth-user                                            OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100
            ...      9     --warning-current-auth-user-prct --critical-current-auth-user-prct                                  OK: Access Points normal state 509 on 525 (96.95%), Access Points user authentications 92.06% (1113 on 1209) | 'total'=525;;;0; 'normal'=509;;;0; 'fault'=16;;;0; 'normal-prct'=96.95%;;;0;100 'fault-prct'=3.05%;;;0;100 'current-user'=1209;;;0; 'current-auth-user'=1113;;;0; 'current-auth-user-prct'=92.06%;;;0;100