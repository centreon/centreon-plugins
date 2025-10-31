*** Settings ***
Documentation       Cloud Prometheus REST API Container

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::alertmanager::restapi::plugin
...                 --mode=alerts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}


*** Test Cases ***
Alerts ${tc}
    [Tags]    cloud    prometheus

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions    expected_result   --
        ...      1     ${EMPTY}
        ...      OK: Alerts active detected: 3, warning: 1, critical: 1, info: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      2     --filter-name="test-alert1"
        ...      OK: Alerts active detected: 1, warning: 1, critical: 0, info: 0 | 'alerts.active.count'=1;;;0;1 'alerts.active.warning.count'=1;;;0;1 'alerts.active.critical.count'=0;;;0;1 'alerts.active.info.count'=0;;;0;1 'alerts.total.count'=1;;;0; 'alerts.unprocessed.count'=0;;;0;1 'alerts.suppressed.count'=0;;;0;1
        ...      3     --filter-name="name-not-existing"
        ...      OK: Alerts active active : skipped (no value(s)), warning: 0, critical: 0, info: 0 | 'alerts.active.warning.count'=0;;;0;0 'alerts.active.critical.count'=0;;;0;0 'alerts.active.info.count'=0;;;0;0 'alerts.total.count'=0;;;0; 'alerts.unprocessed.count'=0;;;0;0 'alerts.suppressed.count'=0;;;0;0
        ...      4     --filter-severity="critical"
        ...      OK: Alerts active detected: 1, warning: 0, critical: 1, info: 0 | 'alerts.active.count'=1;;;0;2 'alerts.active.warning.count'=0;;;0;2 'alerts.active.critical.count'=1;;;0;2 'alerts.active.info.count'=0;;;0;2 'alerts.total.count'=2;;;0; 'alerts.unprocessed.count'=1;;;0;2 'alerts.suppressed.count'=0;;;0;2
        ...      5     --filter-severity="severity-not-existing"
        ...      OK: Alerts active active : skipped (no value(s)), warning: 0, critical: 0, info: 0 | 'alerts.active.warning.count'=0;;;0;0 'alerts.active.critical.count'=0;;;0;0 'alerts.active.info.count'=0;;;0;0 'alerts.total.count'=0;;;0; 'alerts.unprocessed.count'=0;;;0;0 'alerts.suppressed.count'=0;;;0;0
        ...      6     --warning-active=1
        ...      WARNING: Alerts active detected: 3 | 'alerts.active.count'=3;0:1;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      7     --critical-active=1
        ...      CRITICAL: Alerts active detected: 3 | 'alerts.active.count'=3;;0:1;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      8     --warning-active-warning=@1
        ...      WARNING: Alerts active warning: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;@0:1;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      9     --critical-active-warning=@1
        ...      CRITICAL: Alerts active warning: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;@0:1;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      10     --warning-active-critical=@1
        ...      WARNING: Alerts active critical: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;@0:1;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      11     --critical-active-critical=@1
        ...      CRITICAL: Alerts active critical: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;@0:1;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      12     --warning-active-info=@1
        ...      WARNING: Alerts active info: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;@0:1;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      13     --critical-active-info=@1
        ...      CRITICAL: Alerts active info: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;@0:1;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      14     --warning-total=2
        ...      WARNING: Alerts total: 5 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;0:2;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      15     --critical-total=4
        ...      CRITICAL: Alerts total: 5 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;0:4;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      16     --warning-unprocessed=@1
        ...      WARNING: Alerts unprocessed: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;@0:1;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      17     --critical-unprocessed=@1
        ...      CRITICAL: Alerts unprocessed: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;@0:1;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      18     --warning-suppressed=@1
        ...      WARNING: Alerts suppressed: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;@0:1;;0;5
        ...      19     --critical-suppressed=@1
        ...      CRITICAL: Alerts suppressed: 1 | 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;@0:1;0;5


Alerts regex ${tc}
    [Tags]    cloud    prometheus

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions    expected_result   --
        ...      1     --verbose
        ...      OK: Alerts active detected: 3, warning: 1, critical: 1, info: 1 \\\\| 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5
        ...      2     --verbose --display-alerts
        ...      OK: Alerts active detected: 3, warning: 1, critical: 1, info: 1 \\\\| 'alerts.active.count'=3;;;0;5 'alerts.active.warning.count'=1;;;0;5 'alerts.active.critical.count'=1;;;0;5 'alerts.active.info.count'=1;;;0;5 'alerts.total.count'=5;;;0; 'alerts.unprocessed.count'=1;;;0;5 'alerts.suppressed.count'=1;;;0;5\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: active\\\\] \\\\[severity: warning\\\\]: test-alert1\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: active\\\\] \\\\[severity: info\\\\]: test-alert2\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: active\\\\] \\\\[severity: critical\\\\]: test-alert3\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: unprocessed\\\\] \\\\[severity: critical\\\\]: test-alert4\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: suppressed\\\\] \\\\[severity: unknown\\\\]: test-alert5
        ...      3     --verbose --display-alerts --filter-name="test-alert1"
        ...      OK: Alerts active detected: 1, warning: 1, critical: 0, info: 0 \\\\| 'alerts.active.count'=1;;;0;1 'alerts.active.warning.count'=1;;;0;1 'alerts.active.critical.count'=0;;;0;1 'alerts.active.info.count'=0;;;0;1 'alerts.total.count'=1;;;0; 'alerts.unprocessed.count'=0;;;0;1 'alerts.suppressed.count'=0;;;0;1\\\\nalert \\\\[start: \\\\w{3} \\\\w{3} \\\\d{2} \\\\d{4} \\\\d{2}:\\\\d{2}:\\\\d{2} GMT\\\\+\\\\d{4} \\\\(Coordinated Universal Time\\\\)\\\\] \\\\[state: active\\\\] \\\\[severity: warning\\\\]: test-alert1
