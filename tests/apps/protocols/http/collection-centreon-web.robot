*** Settings ***
Documentation       Collections of HTTP Protocol plugin testing a mock of Centreon-web API

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}collection-centreon-web.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::protocols::http::plugin
...                 --mode collection
...                 --constant='hostname=${HOSTNAME}'
...                 --constant='protocol=http'
...                 --constant='port=${APIPORT}'
...                 --constant='username=admin'
...                 --constant='password=myPassword'


*** Test Cases ***
Check if ${test_desc} on Centreon
    [Tags]    centreon    collections    http
    ${command}    Catenate
    ...    ${CMD}    --config=${CURDIR}/${collection}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    test_desc                  collection                                                       expected_result   --
        ...      authentication succeeds    collection-centreon-web-check-auth.collection.json               OK: Authentication resulted in 200 HTTP code
        ...      hosts are down             collection-centreon-web-check-down-hosts.collection.json         OK: All hosts are UP | 'hostsRequest.down.count'=0;0;;0;1
        ...      commands are broken        collection-centreon-web-check-broken-commands.collection.json    WARNING:${SPACE} - Service FakeHostThatIsDown/Svc-BadCommand output is '(Execute command failed)' | 'commands.broken.count'=1;0;;0;
