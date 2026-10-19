*** Settings ***
Documentation       Prometheus cAdvisor exporter - task state mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}metrics.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=task-state
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --url-path=/api/v1


*** Test Cases ***
Task state ${tc}
    [Tags]    cloud    prometheus    cadvisor

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
    ...    --verbose
    ...    OK: All containers tasks states are ok | 'tasks_sleeping_multi_app'=2;;;0; 'tasks_running_multi_app'=0;;;0; 'tasks_stopped_multi_app'=0;;;0; 'tasks_uninterruptible_multi_app'=0;;;0; 'tasks_iowaiting_multi_app'=0;;;0; 'tasks_sleeping_multi_sidecar'=1;;;0; 'tasks_running_multi_sidecar'=0;;;0; 'tasks_stopped_multi_sidecar'=0;;;0; 'tasks_uninterruptible_multi_sidecar'=0;;;0; 'tasks_iowaiting_multi_sidecar'=0;;;0; 'tasks_sleeping_web-1_nginx'=4;;;0; 'tasks_running_web-1_nginx'=1;;;0; 'tasks_stopped_web-1_nginx'=0;;;0; 'tasks_uninterruptible_web-1_nginx'=0;;;0; 'tasks_iowaiting_web-1_nginx'=0;;;0;\nContainer 'app' [pod: multi] Tasks Sleeping: 2, Running: 0, Stopped: 0, Uninterruptible: 0, Iowaiting: 0\nContainer 'sidecar' [pod: multi] Tasks Sleeping: 1, Running: 0, Stopped: 0, Uninterruptible: 0, Iowaiting: 0\nContainer 'nginx' [pod: web-1] Tasks Sleeping: 4, Running: 1, Stopped: 0, Uninterruptible: 0, Iowaiting: 0
    ...    2
    ...    --container='container=""'
    ...    OK: All containers tasks states are ok | 'tasks_sleeping_multi'=3;;;0; 'tasks_running_multi'=0;;;0; 'tasks_stopped_multi'=0;;;0; 'tasks_uninterruptible_multi'=0;;;0; 'tasks_iowaiting_multi'=0;;;0; 'tasks_sleeping_web-1'=5;;;0; 'tasks_running_web-1'=1;;;0; 'tasks_stopped_web-1'=0;;;0; 'tasks_uninterruptible_web-1'=0;;;0; 'tasks_iowaiting_web-1'=0;;;0;
    ...    3
    ...    --container='name="haproxy"'
    ...    OK: Container 'haproxy' Tasks Sleeping: 8, Running: 2, Stopped: 0, Uninterruptible: 1, Iowaiting: 1 | 'tasks_sleeping'=8;;;0; 'tasks_running'=2;;;0; 'tasks_stopped'=0;;;0; 'tasks_uninterruptible'=1;;;0; 'tasks_iowaiting'=1;;;0;
    ...    4
    ...    --critical-running=0
    ...    CRITICAL: Container 'nginx' [pod: web-1] Tasks Running: 1 | 'tasks_sleeping_multi_app'=2;;;0; 'tasks_running_multi_app'=0;;0:0;0; 'tasks_stopped_multi_app'=0;;;0; 'tasks_uninterruptible_multi_app'=0;;;0; 'tasks_iowaiting_multi_app'=0;;;0; 'tasks_sleeping_multi_sidecar'=1;;;0; 'tasks_running_multi_sidecar'=0;;0:0;0; 'tasks_stopped_multi_sidecar'=0;;;0; 'tasks_uninterruptible_multi_sidecar'=0;;;0; 'tasks_iowaiting_multi_sidecar'=0;;;0; 'tasks_sleeping_web-1_nginx'=4;;;0; 'tasks_running_web-1_nginx'=1;;0:0;0; 'tasks_stopped_web-1_nginx'=0;;;0; 'tasks_uninterruptible_web-1_nginx'=0;;;0; 'tasks_iowaiting_web-1_nginx'=0;;;0;
    ...    5
    ...    --container='name="haproxy"' --warning-iowaiting=0
    ...    WARNING: Container 'haproxy' Tasks Iowaiting: 1 | 'tasks_sleeping'=8;;;0; 'tasks_running'=2;;;0; 'tasks_stopped'=0;;;0; 'tasks_uninterruptible'=1;;;0; 'tasks_iowaiting'=1;0:0;;0;
    ...    6
    ...    --container='container="absent"'
    ...    UNKNOWN: No containers found.
    ...    7
    ...    --pod='not a filter'
    ...    UNKNOWN: Need to specify --pod option as a PromQL filter.
