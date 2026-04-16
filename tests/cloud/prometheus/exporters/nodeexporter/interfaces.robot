*** Settings ***
Documentation       Prometheus Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=interfaces --hostname=${HOSTNAME} --port=${APIPORT}



*** Test Cases ***
Interfaces ${tc}
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                        expected_result    --
            ...       1   ${EMPTY}                                             CRITICAL: interface 'dif0' operational status: unknown [admin: up]
            ...       2   --critical-interface-status=0                        OK: All interfaces are ok
            ...       3   --filter-name=eth0                                   OK: interface 'eth0' operational status: up [admin: up]
            ...       4   --filter-name=eth0 --warning-interface-status=1      WARNING: interface 'eth0' operational status: up [admin: up]
            ...       5   --filter-name=eth0 --critical-interface-status=1     CRITICAL: interface 'eth0' operational status: up [admin: up]
