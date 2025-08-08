*** Settings ***
Documentation       List informix instances.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=database::informix::snmp::plugin

*** Test Cases ***
list-instances ${tc}
    [Tags]    database    informix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-instances
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=database/informix/snmp/slim_informix-log
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               List instances: [instance = default]
            ...      2     --filter-instance='instance'                                                                            List instances: [instance = default]