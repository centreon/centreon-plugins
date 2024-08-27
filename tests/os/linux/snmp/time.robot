*** Settings ***
Documentation       Check arp table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
time ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=time
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp    ${output}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --oid=''                        oj
            ...      2     --warning-offset='0'            ^(OK|WARNING|CRITICAL): Time offset (-?\\\d+) second\\\(s\\\): Local Time : (\\\d{4}-\\\d{2}-\\d{2}T\\\d{2}:\\\d{2}:\\\d{2}) \\\(\\\+\\\d{4}\\\) \\\| 'offset'=(-?\\\d+)s;.*$
            ...      3     --critical-offset='125'         CRITICAL: Time offset -1211346 second(s): Local Time : 2024-08-13T10:39:44 (+0200) | 'offset'=-1211346s;;0:125;;
            ...      4     --ntp-hostname='NET'            UNKNOWN: Cannot load module 'Net::NTP'
            ...      5     --ntp-port=123                  oid
            ...      6     --timezone='+0100'              oj
