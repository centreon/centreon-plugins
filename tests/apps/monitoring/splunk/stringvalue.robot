*** Settings ***
Documentation       Splunk API

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}splunk.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::splunk::plugin
...                 --hostname=${HOSTNAME}
...                 --api-username=user
...                 --api-password=PaSsWoRdZ
...                 --proto=http
...                 --port=${APIPORT}
...                 --mode=string-value


*** Test Cases ***
StringValue ${tc}
    [Tags]    splunk    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc       extraoptions                                                                                                          expected_result    --
            ...      1        ${EMPTY}                                                                                                              UNKNOWN: Please set --query option.
            ...      2        --query="ah oui mais non"                                                                                             UNKNOWN: Error: Unknown search command 'ah'.
            ...      3        --query="| tstats count"                                                                                              OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0;
            ...      4        --query="| tstats count" --critical-count=:1                                                                          CRITICAL: Events: 2 | 'splunk.event.count'=2;;0:1;0;
            ...      6        --query="| tstats count" --warning-value='%\\\{sourcetype\\\}=~/mongod/' --warning-label=Zut                          WARNING: event-1 Zut [count: 32] [count2: 312] [sourcetype: mongod] | 'splunk.event.count'=2;;;0;
            ...      7        --query="| tstats count" --event-label=Enreg --verbose                                                                OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; Enreg-0 [count: 120] [count2: 12] [sourcetype: language-server-2] Enreg-1 [count: 32] [count2: 312] [sourcetype: mongod]
            ...      8        --query="| tstats count" --event-field=sourcetype --verbose                                                           OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; language-server-2 [count: 120] [count2: 12] [sourcetype: language-server-2] mongod [count: 32] [count2: 312] [sourcetype: mongod]
