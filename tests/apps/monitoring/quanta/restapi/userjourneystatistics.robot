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
UserJourneyStatistics ${tc}
    [Tags]    quanta    api
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=user-journey-statistics
    ...    --journey-id=3666
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp     ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                          expected_regexp    --
            ...      1        ${EMPTY}                                                              OK: journey "Basic user journey" journey hero time: 35933.10ms, journey speed index: 13754.20ms, journey ttfb: 33.56ms | 'journey_Basic user journey#journey.herotime.milliseconds'=35933.10ms;;;0; 'journey_Basic user journey#journey.speedindex.time.milliseconds'=13754.20ms;;;0; 'journey_Basic user journey#journey.ttfb.milliseconds'=33.56ms;;;0;
            ...      2        --warning-journey-hero-time=:10                                       ^WARNING: journey "Basic user journey" journey hero time.+$
            ...      3        --warning-journey-speed-index=:10                                     ^WARNING: journey "Basic user journey" journey speed index.+$
            ...      4        --critical-journey-ttfb=:10                                           ^CRITICAL: journey "Basic user journey" journey ttfb.+$
            ...      5        --critical-journey-performance-score=:10                              ^CRITICAL: journey "Basic user journey" journey performance score.+$
            ...      6        --show-interactions --critical-interaction-ttfb=:10                   ^CRITICAL: interaction "Home".+$
            ...      7        --show-interactions --warning-interaction-speed-index=:10             ^WARNING: interaction "Home".+$
            ...      8        --show-interactions --critical-interaction-hero-time=:10              ^CRITICAL: interaction "Home".+$
            ...      9        --show-interactions=1 --warning-interaction-performance-score=11:     ^WARNING: interaction "Home".+$
