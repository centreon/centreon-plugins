*** Settings ***
Documentation       Test suite for Apache CXF JMX
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}javacxf.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::java::cxf::jmx::plugin
...                 --mode=list-services
...                 --url=http://${HOSTNAME}:${APIPORT}/jolokia
...                 --username=XXX
...                 --password=XXX
...                 --timeout=5


*** Test Cases ***
listservices ${tc}
    [Tags]    network    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                    expected_result    --
            ...       1     ${EMPTY}                        List services: [service = http://operation_test.dmt/][port = TestJobXXXX][busId = dmt.SELECTION_PARTIN-cxf8642]
