*** Settings ***
Documentation       HAProxy Backend Usage Monitoring

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}mockoon.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::haproxy::web::plugin
...                 --mode=backend-usage
...                 --hostname=${HOSTNAME}
...                 --username='username'
...                 --password='password'
...                 --proto='http'
...                 --port=${APIPORT}


*** Test Cases ***
backend-usage ${tc}
    [Tags]    mockoon    restapi    
    ${command}    Catenate
    ...    ${CMD}
    ...    --filter-name='${filter_name}'
    ...    ${extra_options}
    
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    filter_name         extra_options                                    expected_result    --
            ...      1     STATIC_BG_IMAGE     ${EMPTY}                                         OK: Backend 'STATIC_BG_IMAGE' backend status: UP, current queue: 0, current session rate: 0/s, max session rate: 1/s, current sessions: 0, backend-total-sessions : Buffer creation, backend-traffic-in : Buffer creation, backend-traffic-out : Buffer creation, denied requests: 0, denied responses: 0, connection errors: 0, responses errors: 0 | 'STATIC_BG_IMAGE#backend.queue.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.session.current.rate.countpersecond'=0;;;0; 'STATIC_BG_IMAGE#backend.session.max.rate.countpersecond'=1;;;0; 'STATIC_BG_IMAGE#backend.sessions.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.requests.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.connections.error.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.error.count'=0;;;0;
            ...      2     STATIC_BG_IMAGE     --warning-backend-max-session-rate=0:0           WARNING: Backend 'STATIC_BG_IMAGE' backend max session rate: 1/s | 'STATIC_BG_IMAGE#backend.queue.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.session.current.rate.countpersecond'=0;;;0; 'STATIC_BG_IMAGE#backend.session.max.rate.countpersecond'=1;0:0;;0; 'STATIC_BG_IMAGE#backend.sessions.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.sessions.total.count'=0;;;0; 'STATIC_BG_IMAGE#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'STATIC_BG_IMAGE#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'STATIC_BG_IMAGE#backend.requests.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.connections.error.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.error.count'=0;;;0;
            ...      3     STATIC_BG_IMAGE     --critical-backend-max-session-rate=0:0          CRITICAL: Backend 'STATIC_BG_IMAGE' backend max session rate: 1/s | 'STATIC_BG_IMAGE#backend.queue.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.session.current.rate.countpersecond'=0;;;0; 'STATIC_BG_IMAGE#backend.session.max.rate.countpersecond'=1;;0:0;0; 'STATIC_BG_IMAGE#backend.sessions.current.count'=0;;;0; 'STATIC_BG_IMAGE#backend.sessions.total.count'=0;;;0; 'STATIC_BG_IMAGE#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'STATIC_BG_IMAGE#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'STATIC_BG_IMAGE#backend.requests.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.denied.count'=0;;;0; 'STATIC_BG_IMAGE#backend.connections.error.count'=0;;;0; 'STATIC_BG_IMAGE#backend.responses.error.count'=0;;;0;
            ...      4     APP-IHM             ${EMPTY}                                         OK: Backend 'APP-IHM' backend status: UP, current queue: 0, current session rate: 1/s, max session rate: 25/s, current sessions: 0, backend-total-sessions : Buffer creation, backend-traffic-in : Buffer creation, backend-traffic-out : Buffer creation, denied requests: 0, denied responses: 0, connection errors: 1, responses errors: 0 | 'APP-IHM#backend.queue.current.count'=0;;;0; 'APP-IHM#backend.session.current.rate.countpersecond'=1;;;0; 'APP-IHM#backend.session.max.rate.countpersecond'=25;;;0; 'APP-IHM#backend.sessions.current.count'=0;;;0; 'APP-IHM#backend.requests.denied.count'=0;;;0; 'APP-IHM#backend.responses.denied.count'=0;;;0; 'APP-IHM#backend.connections.error.count'=1;;;0; 'APP-IHM#backend.responses.error.count'=0;;;0;
            ...      5     APP-IHM             --warning-backend-current-session-rate=0:0       WARNING: Backend 'APP-IHM' backend current session rate: 1/s | 'APP-IHM#backend.queue.current.count'=0;;;0; 'APP-IHM#backend.session.current.rate.countpersecond'=1;0:0;;0; 'APP-IHM#backend.session.max.rate.countpersecond'=25;;;0; 'APP-IHM#backend.sessions.current.count'=0;;;0; 'APP-IHM#backend.sessions.total.count'=0;;;0; 'APP-IHM#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'APP-IHM#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'APP-IHM#backend.requests.denied.count'=0;;;0; 'APP-IHM#backend.responses.denied.count'=0;;;0; 'APP-IHM#backend.connections.error.count'=1;;;0; 'APP-IHM#backend.responses.error.count'=0;;;0;
            ...      6     APP-IHM             --critical-backend-current-session-rate=0:0      CRITICAL: Backend 'APP-IHM' backend current session rate: 1/s | 'APP-IHM#backend.queue.current.count'=0;;;0; 'APP-IHM#backend.session.current.rate.countpersecond'=1;;0:0;0; 'APP-IHM#backend.session.max.rate.countpersecond'=25;;;0; 'APP-IHM#backend.sessions.current.count'=0;;;0; 'APP-IHM#backend.sessions.total.count'=0;;;0; 'APP-IHM#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'APP-IHM#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'APP-IHM#backend.requests.denied.count'=0;;;0; 'APP-IHM#backend.responses.denied.count'=0;;;0; 'APP-IHM#backend.connections.error.count'=1;;;0; 'APP-IHM#backend.responses.error.count'=0;;;0;
            ...      7     APP-RIA             ${EMPTY}                                         OK: Backend 'APP-RIA' backend status: UP, current queue: 0, current session rate: 0/s, max session rate: 0/s, current sessions: 0, backend-total-sessions : Buffer creation, backend-traffic-in : Buffer creation, backend-traffic-out : Buffer creation, denied requests: 0, denied responses: 0, connection errors: 0, responses errors: 0 | 'APP-RIA#backend.queue.current.count'=0;;;0; 'APP-RIA#backend.session.current.rate.countpersecond'=0;;;0; 'APP-RIA#backend.session.max.rate.countpersecond'=0;;;0; 'APP-RIA#backend.sessions.current.count'=0;;;0; 'APP-RIA#backend.requests.denied.count'=0;;;0; 'APP-RIA#backend.responses.denied.count'=0;;;0; 'APP-RIA#backend.connections.error.count'=0;;;0; 'APP-RIA#backend.responses.error.count'=0;;;0;
            ...      8     APP-RIA             --warning-backend-denied-requests=1:1            WARNING: Backend 'APP-RIA' backend denied requests: 0 | 'APP-RIA#backend.queue.current.count'=0;;;0; 'APP-RIA#backend.session.current.rate.countpersecond'=0;;;0; 'APP-RIA#backend.session.max.rate.countpersecond'=0;;;0; 'APP-RIA#backend.sessions.current.count'=0;;;0; 'APP-RIA#backend.sessions.total.count'=0;;;0; 'APP-RIA#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'APP-RIA#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'APP-RIA#backend.requests.denied.count'=0;1:1;;0; 'APP-RIA#backend.responses.denied.count'=0;;;0; 'APP-RIA#backend.connections.error.count'=0;;;0; 'APP-RIA#backend.responses.error.count'=0;;;0;
            ...      9     APP-RIA             --critical-backend-denied-requests=1:1           CRITICAL: Backend 'APP-RIA' backend denied requests: 0 | 'APP-RIA#backend.queue.current.count'=0;;;0; 'APP-RIA#backend.session.current.rate.countpersecond'=0;;;0; 'APP-RIA#backend.session.max.rate.countpersecond'=0;;;0; 'APP-RIA#backend.sessions.current.count'=0;;;0; 'APP-RIA#backend.sessions.total.count'=0;;;0; 'APP-RIA#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'APP-RIA#backend.traffic.out.bitpersecond'=0.00b/s;;;0; 'APP-RIA#backend.requests.denied.count'=0;;1:1;0; 'APP-RIA#backend.responses.denied.count'=0;;;0; 'APP-RIA#backend.connections.error.count'=0;;;0; 'APP-RIA#backend.responses.error.count'=0;;;0;



