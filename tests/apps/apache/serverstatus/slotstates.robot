*** Comments ***
# Note: With these tests a counter is incremented in the Mockoon mock data.
# To reset it, make sure to restart the Mockoon server before each robot execution.


*** Settings ***
Documentation       Check Apache WebServer SloteStates statistics

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}serverstatus.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::apache::serverstatus::plugin
...                 --mode=slotstates
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}


*** Test Cases ***
SloteStates ${tc}
    [Tags]    apps    apache    serverstatus

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                               expected_result    --
        ...      1     ${EMPTY}                                                                    OK: Slots busy: 1 (0.67 %), free: 149 (99.33 %), waiting: 5 (3.33 %), starting: 0 (0.00 %), reading: 0 (0.00 %), sending: 1 (0.67 %), keepalive: 0 (0.00 %), dns lookup: 0 (0.00 %), closing: 0 (0.00 %), logging: 0 (0.00 %), gracefully finishing: 0 (0.00 %), idle cleanup worker: 0 (0.00 %) | 'apache.slot.busy.count'=1;;;0;150 'apache.slot.free.count'=149;;;0;150 'apache.slot.waiting.count'=5;;;0;150 'apache.slot.starting.count'=0;;;0;150 'apache.slot.reading.count'=0;;;0;150 'apache.slot.sending.count'=1;;;0;150 'apache.slot.keepalive.count'=0;;;0;150 'apache.slot.dnslookup.count'=0;;;0;150 'apache.slot.closing.count'=0;;;0;150 'apache.slot.logging.count'=0;;;0;150 'apache.slot.gracefullyfinishing.count'=0;;;0;150 'apache.slot.idlecleanupworker.count'=0;;;0;150
        ...      2     --warning-gracefully-finishing=10:                                          WARNING: Slots gracefully finishing: 0 (0.00 %) | 'apache.slot.busy.count'=1;;;0;150 'apache.slot.free.count'=149;;;0;150 'apache.slot.waiting.count'=5;;;0;150 'apache.slot.starting.count'=0;;;0;150 'apache.slot.reading.count'=0;;;0;150 'apache.slot.sending.count'=1;;;0;150 'apache.slot.keepalive.count'=0;;;0;150 'apache.slot.dnslookup.count'=0;;;0;150 'apache.slot.closing.count'=0;;;0;150 'apache.slot.logging.count'=0;;;0;150 'apache.slot.gracefullyfinishing.count'=0;15:;;0;150 'apache.slot.idlecleanupworker.count'=0;;;0;150
        ...      3     --critical-apache-slot-gracefullyfinishing-count=10:                        CRITICAL: Slots gracefully finishing: 0 (0.00 %) | 'apache.slot.busy.count'=1;;;0;150 'apache.slot.free.count'=149;;;0;150 'apache.slot.waiting.count'=5;;;0;150 'apache.slot.starting.count'=0;;;0;150 'apache.slot.reading.count'=0;;;0;150 'apache.slot.sending.count'=1;;;0;150 'apache.slot.keepalive.count'=0;;;0;150 'apache.slot.dnslookup.count'=0;;;0;150 'apache.slot.closing.count'=0;;;0;150 'apache.slot.logging.count'=0;;;0;150 'apache.slot.gracefullyfinishing.count'=0;;15:;0;150 'apache.slot.idlecleanupworker.count'=0;;;0;150
        ...      4     --warning-gracefuly-finished=10:                                            WARNING: Slots gracefully finishing: 0 (0.00 %) | 'apache.slot.busy.count'=1;;;0;150 'apache.slot.free.count'=149;;;0;150 'apache.slot.waiting.count'=5;;;0;150 'apache.slot.starting.count'=0;;;0;150 'apache.slot.reading.count'=0;;;0;150 'apache.slot.sending.count'=1;;;0;150 'apache.slot.keepalive.count'=0;;;0;150 'apache.slot.dnslookup.count'=0;;;0;150 'apache.slot.closing.count'=0;;;0;150 'apache.slot.logging.count'=0;;;0;150 'apache.slot.gracefullyfinishing.count'=0;15:;;0;150 'apache.slot.idlecleanupworker.count'=0;;;0;150
        ...      5     --critical-apache-slot-gracefulyfinished-count=10:                          CRITICAL: Slots gracefully finishing: 0 (0.00 %) | 'apache.slot.busy.count'=1;;;0;150 'apache.slot.free.count'=149;;;0;150 'apache.slot.waiting.count'=5;;;0;150 'apache.slot.starting.count'=0;;;0;150 'apache.slot.reading.count'=0;;;0;150 'apache.slot.sending.count'=1;;;0;150 'apache.slot.keepalive.count'=0;;;0;150 'apache.slot.dnslookup.count'=0;;;0;150 'apache.slot.closing.count'=0;;;0;150 'apache.slot.logging.count'=0;;;0;150 'apache.slot.gracefullyfinishing.count'=0;;15:;0;150 'apache.slot.idlecleanupworker.count'=0;;;0;150
