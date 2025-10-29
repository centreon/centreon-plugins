*** Settings ***
Documentation       Check UPS APC through SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::ups::apc::snmp::plugin
...         --mode=time
...         --hostname=${HOSTNAME}
...         --snmp-version=${SNMPVERSION}
...         --snmp-port=${SNMPPORT}
...         --snmp-timeout=5


*** Test Cases ***
time ${tc}
    [Tags]    hardware    ups    apc    ntp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/time
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extra_options                  expected_regexp    --
    ...          1     ${EMPTY}                       ^OK: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T08:50:07 \\\\(UTC\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;;;$
    ...          2     --ntp-port=8080                ^OK: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T08:50:07 \\\\(UTC\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;;;$
    ...          3     --timezone='Europe/London'     ^OK: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T09:50:07 \\\\(Europe/London\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;;;$
    ...          5     --timezone='Europe/Paris'      ^OK: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T10:50:07 \\\\(Europe/Paris\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;;;$
    ...          6     --timezone='Japan/Tokyo'       ^UNKNOWN: Timezone 'Japan/Tokyo' does not exist.$
    ...          7     --timezone='Asia/Tokyo'        ^OK: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T17:50:07 \\\\(Asia/Tokyo\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;;;$
    ...          8     --warning-offset='0'           ^WARNING: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T08:50:07 \\\\(UTC\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;0:0;;;$
    ...          9     --critical-offset='0'          ^CRITICAL: Time offset -?\\\\d+ second\\\\(s\\\\): Local Time : 2025-08-26T08:50:07 \\\\(UTC\\\\) \\\\| 'time\\\\.offset\\\\.seconds'=-?\\\\d+s;;0:0;;$
    ...         10     --timezone='doesnt/exist'      UNKNOWN: Timezone 'doesnt/exist' does not exist.
