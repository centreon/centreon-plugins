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
...                 --mode=numeric-value


*** Test Cases ***
NumericValue ${tc}
    [Tags]    splunk    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc       extraoptions                                          expected_result    --
            ...      1        ${EMPTY}                                                                                                              UNKNOWN: Please set --query option.
            ...      2        --query="ah oui mais non"                                                                                             UNKNOWN: Error: Unknown search command 'ah'.
            ...      3        --query="| tstats count"                                                                                              OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; 'event-0#count'=120;;;; 'event-0#count2'=12;;;; 'event-1#count'=32;;;; 'event-1#count2'=312;;;;
            ...      4        --query="| tstats count" --exclude="count2"                                                                           OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; 'event-0#count'=120;;;; 'event-1#count'=32;;;;
            ...      5        --query="| tstats count" --exclude="count2" --critical-count=:1                                                       CRITICAL: Events: 2 | 'splunk.event.count'=2;;0:1;0; 'event-0#count'=120;;;; 'event-1#count'=32;;;;
            ...      6        --query="| tstats count" --exclude=count2 --warning-value=count=:10 --warning-label=Zut                               WARNING: event-0 Zut [count: 120] - event-1 Zut [count: 32] | 'splunk.event.count'=2;;;0; 'event-0#count'=120;0:10;;; 'event-1#count'=32;0:10;;;
            ...      7        --query="| tstats count" --event-label=Enreg --perfdata-name="count2=CoUnT" --perfdata-min=10 --perfdata-max=100      OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; 'Enreg-0#count'=120;;;10;100 'Enreg-0#CoUnT'=12;;;10;100 'Enreg-1#count'=32;;;10;100 'Enreg-1#CoUnT'=312;;;10;100
            ...      8        --query="| tstats count" --event-field=sourcetype                                                                     OK: Events: 2 - All values are OK | 'splunk.event.count'=2;;;0; 'language-server-2#count'=120;;;; 'language-server-2#count2'=12;;;; 'mongod#count'=32;;;; 'mongod#count2'=312;;;;
