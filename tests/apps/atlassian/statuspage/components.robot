*** Settings ***
Documentation     Atlassian Statuspage components

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
...                --mode=components


*** Test Cases ***
Components ${tc}
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
    ...    CRITICAL: Component 'User space' status: major_outage WARNING: Component 'API' status: degraded_performance - Component 'Dashboard' status: partial_outage
    ...    2
    ...    status.example.com
    ...    --include-name='^(Web services|API)$'
    ...    WARNING: Component 'API' status: degraded_performance
    ...    3
    ...    status.example.com
    ...    --exclude-name='^(API|User space)$'
    ...    WARNING: Component 'Dashboard' status: partial_outage
    ...    4
    ...    status.example.com
    ...    --include-id='^abcde0000001$'
    ...    OK: Component 'Web services' status: operational
    ...    5
    ...    status.example.com
    ...    --exclude-id='^abcde000000[234]$'
    ...    OK: All components are ok
    ...    6
    ...    status.example.com
    ...    --include-name='^Unknown$'
    ...    UNKNOWN: No component found.
    ...    7
    ...    status.example.com
    ...    --warning-status='' --critical-status='\\\%{status} =~ /under_maintenance/'
    ...    CRITICAL: Component 'Storage' status: under_maintenance
    ...    8
    ...    status.example.com
    ...    --warning-status='\\\%{name} eq "Web services"' --critical-status=''
    ...    WARNING: Component 'Web services' status: operational
    ...    9
    ...    no-components.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: No component found.
    ...    10
    ...    invalid-json.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot decode response (add --debug option to display returned content)
    ...    11
    ...    status.example.com
    ...    --api-path=/bad/api/path/
    ...    UNKNOWN: 404 Not Found
    ...    12
    ...    status.example.com
    ...    --api-path=/bad/api/path/ --unknown-http-status='' --warning-http-status='\\\%{http_code} == 404'
    ...    WARNING: 404 Not Found
