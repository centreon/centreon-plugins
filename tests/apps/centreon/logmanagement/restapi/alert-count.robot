*** Settings ***
Documentation       apps::centreon::logmanagement::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::centreon::logmanagement::restapi::plugin
...                 --mode=alert-count
...                 --hostname=${HOSTNAME}
...                 --org=org
...                 --proto=http
...                 --port=${APIPORT}
...                 --token=token
...                 --timeout=10
...                 --unknown-http-status=unknown-http-status
...                 --warning-http-status=warning-http-status
...                 --critical-http-status=critical-http-status


*** Test Cases ***
Alert-count ${tc}
    [Tags]    apps    centreon    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: total: 5, unknown: 1, ok: 4, warn: 0, error: 0, critical: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    2
    ...    --accepted-statuses=unknown
    ...    OK: total: 1, unknown: 1 | 'alerts.total.count'=1;;;0; 'alerts.unknown.count'=1;;;0;
    ...    3
    ...    --include-name=Apache
    ...    OK: total: 2, unknown: 1, ok: 1, warn: 0, error: 0, critical: 0 | 'alerts.total.count'=2;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=1;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    4
    ...    --exclude-name=Apache
    ...    OK: total: 3, unknown: 0, ok: 3, warn: 0, error: 0, critical: 0 | 'alerts.total.count'=3;;;0; 'alerts.unknown.count'=0;;;0; 'alerts.ok.count'=3;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    5
    ...    --include-message=during
    ...    OK: total: 1, unknown: 1, ok: 0, warn: 0, error: 0, critical: 0 | 'alerts.total.count'=1;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=0;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    6
    ...    --exclude-message=during
    ...    OK: total: 4, unknown: 0, ok: 4, warn: 0, error: 0, critical: 0 | 'alerts.total.count'=4;;;0; 'alerts.unknown.count'=0;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    7
    ...    --warning-critical-alerts=1:
    ...    WARNING: critical: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;1:;;0;
    ...    8
    ...    --critical-critical-alerts=1:
    ...    CRITICAL: critical: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;1:;0;
    ...    9
    ...    --warning-error-alerts=1:
    ...    WARNING: error: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;1:;;0; 'alerts.critical.count'=0;;;0;
    ...    10
    ...    --critical-error-alerts=1:
    ...    CRITICAL: error: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;1:;0; 'alerts.critical.count'=0;;;0;
    ...    11
    ...    --warning-ok-alerts=1
    ...    WARNING: ok: 4 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;0:1;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    12
    ...    --critical-ok-alerts=1
    ...    CRITICAL: ok: 4 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;0:1;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    13
    ...    --warning-total-alerts=1
    ...    WARNING: total: 5 | 'alerts.total.count'=5;0:1;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    14
    ...    --critical-total-alerts=1
    ...    CRITICAL: total: 5 | 'alerts.total.count'=5;;0:1;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    15
    ...    --warning-unknown-alerts=0
    ...    WARNING: unknown: 1 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;0:0;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    16
    ...    --critical-unknown-alerts=0
    ...    CRITICAL: unknown: 1 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;0:0;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    17
    ...    --warning-warn-alerts=1:
    ...    WARNING: warn: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;1:;;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
    ...    18
    ...    --critical-warn-alerts=1:
    ...    CRITICAL: warn: 0 | 'alerts.total.count'=5;;;0; 'alerts.unknown.count'=1;;;0; 'alerts.ok.count'=4;;;0; 'alerts.warn.count'=0;;1:;0; 'alerts.error.count'=0;;;0; 'alerts.critical.count'=0;;;0;
