*** Settings ***
Documentation       Prometheus Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=storage --hostname=${HOSTNAME} --port=${APIPORT}



*** Test Cases ***
Storage ${tc}
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                expected_result    --
            ...       1   ${EMPTY}                     OK: Node '127.0.0.1:9101' All storages usage are ok
