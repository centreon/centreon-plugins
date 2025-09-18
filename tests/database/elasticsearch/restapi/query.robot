*** Settings ***
Documentation       Perform Query against the Elasticsearch API

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}elastic-query.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=database::elasticsearch::restapi::plugin
...                 --mode=query
...                 --hostname=${HOSTNAME}
...                 --username=xx
...                 --password=xx
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
query ${tc}
    [Tags]    database    elasticsearch    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                     expected_result    --
            ...      1     ${EMPTY}                                                                                          UNKNOWN: Please set --query option.
            ...      2     --query=TOCRES                                                                                    OK: Result count: 1 - Result #0: '1VHGV5kBLjKQBdDbh548' | 'query.match.count'=1;;;0;
            ...      3     --query=TOCRES --lookup='$.hits.hits[0]._source.nom'                                              OK: Result count: 1 - Result #0: 'TOCRES' | 'query.match.count'=1;;;0;
            ...      4     --query='{ "query": { "match": { "ville": "Saint" } } }'                                          OK: Result count: 1 - Result #0: 'aaHGV5kBLjKQBdDbh548' | 'query.match.count'=1;;;0;
            ...      5     --query='{ "query": { "match": { "ville": "Saint" } } }' --lookup='$.hits.hits[0]._source.nom'    OK: Result count: 1 - Result #0: 'MOUSTIQUE' | 'query.match.count'=1;;;0;
            ...      6     --query=TOCRES --warning-count=10:                                                                WARNING: Result count: 1 | 'query.match.count'=1;10:;;0;
            ...      7     --query=TOCRES --lookup='$.hits.hits[0]._source.nom' --critical-value='\\\%{value} =~ /CRE/'      CRITICAL: Result #0: 'TOCRES' | 'query.match.count'=1;;;0;
