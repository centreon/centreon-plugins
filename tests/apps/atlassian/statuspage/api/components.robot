*** Settings ***
Documentation     Atlassian Statuspage components

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}atlassian-statuspage.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::atlassian::statuspage::api::plugin
...                --custommode=json
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
    ...    CRITICAL: Component 'User space' status: major outage WARNING: Component 'API' status: degraded performance - Component 'Dashboard' status: partial outage
    ...    2
    ...    status.example.com
    ...    --include-name='^(Web services|API)$'
    ...    WARNING: Component 'API' status: degraded performance
    ...    3
    ...    status.example.com
    ...    --exclude-name='^(API|User space)$'
    ...    WARNING: Component 'Dashboard' status: partial outage
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
    ...    --warning-status='' --critical-status='\\\%{status} =~ /under maintenance/'
    ...    CRITICAL: Component 'Storage' status: under maintenance
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
    ...    13
    ...    groups.example.com
    ...    ${EMPTY}
    ...    CRITICAL: Component 'Tokyo' [group: Asia] status: major outage WARNING: Component 'Frankfurt' [group: Europe] status: partial outage - Component 'Global' [group: Asia] status: degraded performance UNKNOWN: Component 'Dashboard' status: unknown
    ...    14
    ...    groups.example.com
    ...    --include-group='^Europe$'
    ...    WARNING: Component 'Frankfurt' [group: Europe] status: partial outage
    ...    15
    ...    groups.example.com
    ...    --exclude-group='^Asia$'
    ...    WARNING: Component 'Frankfurt' [group: Europe] status: partial outage UNKNOWN: Component 'Dashboard' status: unknown
    ...    16
    ...    groups.example.com
    ...    --include-name='^Global$' --verbose
    ...    WARNING: Component 'Global' [group: Asia] status: degraded performance \nComponent 'Global' [group: Europe] status: operational\nComponent 'Global' [group: Asia] status: degraded performance
    ...    17
    ...    groups.example.com
    ...    --unknown-status='' --warning-status='\\\%{group} eq "Europe" and \\\%{status} ne "operational"' --critical-status=''
    ...    WARNING: Component 'Frankfurt' [group: Europe] status: partial outage

Components discovery ${tc}
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
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <element>id</element>\n \ <element>name</element>\n \ <element>group</element>\n \ <element>status</element>\n</data>
    ...    2
    ...    status.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <label group="" id="abcde0000002" name="API" status="degraded performance"/>\n \ <label group="" id="abcde0000003" name="Dashboard" status="partial outage"/>\n \ <label group="" id="abcde0000005" name="Storage" status="under maintenance"/>\n \ <label group="" id="abcde0000004" name="User space" status="major outage"/>\n \ <label group="" id="abcde0000001" name="Web services" status="operational"/>\n</data>
    ...    3
    ...    status.example.com
    ...    --disco-show --exclude-id='^abcde000000[234]$'
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <label group="" id="abcde0000005" name="Storage" status="under maintenance"/>\n \ <label group="" id="abcde0000001" name="Web services" status="operational"/>\n</data>
    ...    4
    ...    no-components.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data/>
    ...    5
    ...    groups.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?>\n<data>\n \ <label group="" id="abcde0000013" name="Billing" status="operational"/>\n \ <label group="" id="abcde0000014" name="Dashboard" status="unknown"/>\n \ <label group="Asia" id="abcde0000012" name="Global" status="degraded performance"/>\n \ <label group="Asia" id="abcde0000011" name="Tokyo" status="major outage"/>\n \ <label group="Europe" id="abcde0000008" name="Frankfurt" status="partial outage"/>\n \ <label group="Europe" id="abcde0000009" name="Global" status="operational"/>\n \ <label group="Europe" id="abcde0000007" name="Paris" status="operational"/>\n</data>
