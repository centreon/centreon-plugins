*** Settings ***
Resource        ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup     Ctn Generic Suite Setup
Test Timeout    120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
swap ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --verbose
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;;0;4294967296 Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%)
    ...    2
    ...    --warning-usage=0
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;0:0;;0;4294967296
    ...    3
    ...    --critical-usage=0
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;0:0;0;4294967296
    ...    4
    ...    --warning-total-usage=4
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;;0;4294967296
    ...    5
    ...    --critical-total-usage=3
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;;0;4294967296
    ...    6
    ...    --warning-total-active=4
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;;0;4294967296
    ...    7
    ...    --critical-total-active=3
    ...    OK: Page space 'Anonymized 162' Usage Total: 4.00 GB Used: 0.00 B (0.00%) Free: 4.00 GB (100.00%) | 'page_space'=0B;;;0;4294967296
