*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=5
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                    expected_result    --
            ...      1     ${EMPTY} --storage=2                             OK: Storage '/dev/hd2' Usage Total: 5.00 GB Used: 3.35 GB (66.97%) Free: 1.65 GB (33.03%) | 'count'=1;;;0; 'used'=3595264000B;;;0;5368709120
            ...      2     --warning-usage=45 --storage=1                   WARNING: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'used'=522375168B;0:483183820;;0;1073741824
            ...      3     --critical-usage=40 --storage=1                  CRITICAL: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'used'=522375168B;;0:429496729;0;1073741824
            ...      4     --free --warning-usage=45 --storage=1            WARNING: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'free'=551366656B;0:483183820;;0;1073741824
            ...      5     --free --critical-usage=45 --storage=1           CRITICAL: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'free'=551366656B;;0:483183820;0;1073741824
