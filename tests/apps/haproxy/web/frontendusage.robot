*** Settings ***
Documentation       HAProxy Frontend Usage Monitoring

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::haproxy::web::plugin
...                 --mode=frontend-usage
...                 --hostname=${HOSTNAME}
...                 --username='username'
...                 --password='password'
...                 --proto='http'
...                 --port=${APIPORT}


*** Test Cases ***
frontend-usage ${tc}
    [Tags]    mockoon    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --filter-name='${filter_name}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter_name          extra_options                                           expected_result    --
            ...      1      ${EMPTY}            ${EMPTY}                                                OK: Frontend 'hafrontend' frontend status: OPEN, current session rate: 1/s, max session rate: 6/s, current sessions: 10, total sessions: 3980, max sessions: 16, frontend-traffic-in : Buffer creation, frontend-traffic-out : Buffer creation, denied requests: 0, denied responses: 0, error requests: 42 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      2      hafrontend          ${EMPTY}                                                OK: Frontend 'hafrontend' frontend status: OPEN, current session rate: 1/s, max session rate: 6/s, current sessions: 10, total sessions: 3980, max sessions: 16, frontend-traffic-in : Buffer creation, frontend-traffic-out : Buffer creation, denied requests: 0, denied responses: 0, error requests: 42 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      3      none                ${EMPTY}                                                UNKNOWN: No Frontend found.
            ...      4      hafrontend          --warning-frontend-current-session-rate=0:0             WARNING: Frontend 'hafrontend' frontend current session rate: 1/s | 'hafrontend#frontend.session.current.rate.countpersecond'=1;0:0;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      5      hafrontend          --critical-frontend-current-session-rate=0:0            CRITICAL: Frontend 'hafrontend' frontend current session rate: 1/s | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;0:0;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      6      hafrontend          --warning-frontend-max-session-rate=0:0                 WARNING: Frontend 'hafrontend' frontend max session rate: 6/s | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;0:0;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      7      hafrontend          --critical-frontend-max-session-rate=0:0                CRITICAL: Frontend 'hafrontend' frontend max session rate: 6/s | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;0:0;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      8      hafrontend          --warning-frontend-current-sessions=0:0                 WARNING: Frontend 'hafrontend' frontend current sessions: 10 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;0:0;;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      9      hafrontend          --critical-frontend-current-sessions=0:0                CRITICAL: Frontend 'hafrontend' frontend current sessions: 10 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;0:0;0; 'hafrontend#frontend.sessions.total.count'=3980;;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      10     hafrontend          --warning-frontend-total-sessions=0:0                   WARNING: Frontend 'hafrontend' frontend total sessions: 3980 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;0:0;;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
            ...      11     hafrontend          --critical-frontend-total-sessions=0:0                  CRITICAL: Frontend 'hafrontend' frontend total sessions: 3980 | 'hafrontend#frontend.session.current.rate.countpersecond'=1;;;0; 'hafrontend#frontend.session.max.rate.countpersecond'=6;;;0; 'hafrontend#frontend.sessions.current.count'=10;;;0; 'hafrontend#frontend.sessions.total.count'=3980;;0:0;0; 'hafrontend#frontend.sessions.maximum.count'=16;;;0; 'hafrontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0; 'hafrontend#frontend.requests.denied.count'=0;;;0; 'hafrontend#frontend.responses.denied.count'=0;;;0; 'hafrontend#frontend.requests.error.count'=42;;;0;
