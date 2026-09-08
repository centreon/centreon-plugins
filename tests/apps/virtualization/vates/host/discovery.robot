*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::virtualization::vates::host::plugin
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --mode=discovery
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    virtualization    xenorchestra    host    discovery
    ${command}    Catenate    ${CMD} ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extra_options    expected_result    --
    ...    1    ${EMPTY}
    ...    "discovered_items":3
    ...    2    --filter-power-states=Running
    ...    "discovered_items":2
