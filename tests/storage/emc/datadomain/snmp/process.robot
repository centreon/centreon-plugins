*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
process ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=process
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                     expected_result    --
            ...      1     --verbose                                                         OK: NFS status: enabled - CIFS status: enabledRunning - DDBoost status: enabled - VTL process state: stopped [admin state: disabled] 
            ...      2     --unknown-cifs-status=\\\%{cifsStatus}                            UNKNOWN: CIFS status: enabledRunning
            ...      3     --warning-cifs-status=\\\%{cifsStatus}                            WARNING: CIFS status: enabledRunning
            ...      4     --critical-cifs-status=\\\%{cifsStatus}                           CRITICAL: CIFS status: enabledRunning
            ...      5     --unknown-ddboost-status=\\\%{ddboostStatus}                      UNKNOWN: DDBoost status: enabled
            ...      6     --warning-ddboost-status=\\\%{ddboostStatus}                      WARNING: DDBoost status: enabled
            ...      7     --critical-ddboost-status=\\\%{ddboostStatus}                     CRITICAL: DDBoost status: enabled
            ...      8     --unknown-nfs-status=\\\%{nfsStatus}                              UNKNOWN: NFS status: enabled
            ...      9     --warning-nfs-status=\\\%{nfsStatus}                              WARNING: NFS status: enabled
            ...      10    --critical-nfs-status=\\\%{nfsStatus}                             CRITICAL: NFS status: enabled
            ...      11    --unknown-vtl-status='\\\%{vtlAdminState} =~ /failed/'            OK: NFS status: enabled - CIFS status: enabledRunning - DDBoost status: enabled - VTL process state: stopped [admin state: disabled]
            ...      12    --warning-vtl-status='\\\%{vtlAdminState} =~ /failed/'            OK: NFS status: enabled - CIFS status: enabledRunning - DDBoost status: enabled - VTL process state: stopped [admin state: disabled]
            ...      13    --critical-vtl-status='\\\%{vtlAdminState} =~ /failed/'           OK: NFS status: enabled - CIFS status: enabledRunning - DDBoost status: enabled - VTL process state: stopped [admin state: disabled]
