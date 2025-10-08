*** Settings ***
Documentation       Check system uptime.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                             expected_result    --
            ...      1     --verbose                                                 OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      2     --warning-uptime                                          OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      3     --critical-uptime                                         OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      4     --add-sysdesc                                             OK: System uptime is: 288d 20h 33m 6s, Anonymized 023 | 'uptime'=24957186.00s;;;0;
            ...      5     --force-oid=.1.3.6.1.2.1.1.3.0                            OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      6     --check-overload                                          OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      7     --reboot-window                                           OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      8     --unit='s'                                                OK: System uptime is: 288d 20h 33m 6s | 'uptime'=24957186.00s;;;0;
            ...      9     --unit='m'                                                OK: System uptime is: 288d 20h 33m 6s | 'uptime'=415953.10m;;;0;
