*** Settings ***
Documentation     Atlassian Statuspage list-components

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}atlassian-statuspage.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::atlassian::statuspage::plugin
...                --http-peer-addr=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --mode=list-components


*** Test Cases ***
List components ${tc}
    [Tags]    apps    atlassian    statuspage    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    status.example.com
    ...    ${EMPTY}
    ...    List components: \n[id: abcde0000001][name: Web services][status: operational]\n[id: abcde0000002][name: API][status: degraded_performance]\n[id: abcde0000003][name: Dashboard][status: partial_outage]\n[id: abcde0000004][name: User space][status: major_outage]\n[id: abcde0000005][name: Storage][status: under_maintenance]
    ...    2
    ...    no-components.example.com
    ...    ${EMPTY}
    ...    List components:
    ...    3
    ...    status.example.com
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <element>id</element>\n \ <element>name</element>\n \ <element>status</element>\n</data>
    ...    4
    ...    status.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <label id="abcde0000001" name="Web services" status="operational"/>\n \ <label id="abcde0000002" name="API" status="degraded_performance"/>\n \ <label id="abcde0000003" name="Dashboard" status="partial_outage"/>\n \ <label id="abcde0000004" name="User space" status="major_outage"/>\n \ <label id="abcde0000005" name="Storage" status="under_maintenance"/>\n</data>
