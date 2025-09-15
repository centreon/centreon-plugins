*** Settings ***
Documentation       Quanta

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}quanta.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::quanta::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-token=PaSsWoRd
...                 --site-id=10
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
SiteOverview ${tc}
    [Tags]    quanta    api
    ${command}    Catenate
...    ${CMD}
    ...    --mode=site-overview
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc       extraoptions                                          expected_result    --
            ...      1        ${EMPTY}                                              OK: Site 'www.ariege.com' performance score: 72, digital sobriety score: 56, eco design score: 62, carbon footprint per click: 1.28g | 'www.ariege.com#performance.score'=72;;;0;100 'www.ariege.com#digitalsobriety.score'=56;;;0;100 'www.ariege.com#ecodesign.score'=62;;;0;100 'www.ariege.com#perclick.carbon.footprint.gramm'=1.28g;;;0;
