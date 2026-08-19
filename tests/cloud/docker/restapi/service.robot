*** Settings ***
Documentation       Cloud Docker REST API Services

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}docker-service.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::docker::restapi::plugin
...                 --mode=service-status
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}


*** Test Cases ***
Service status ${tc}
    [Tags]    cloud    kubernetes

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: service 'centreon4' (101112) - service 'centreon2' (456) - service 'centreon3' task 'mno' state: failed [node: 127.0.0.1 (node1)] [container: container1] [desired state: running] [message: failed] | 'services.tasks.total.count'=8;;;0; 'services.tasks.problems.count'=1;;;0; 'centreon4#service.tasks.problems.count'=0;;;0; 'centreon4#service.replica.count'=2;;;0; 'centreon4#service.tasks.count'=2;;;0; 'centreon4#service.tasks.running.count'=1;;;0; 'centreon4#service.tasks.shutdown.count'=0;;;0; 'centreon4#service.tasks.failed.count'=0;;;0; 'centreon4#service.tasks.restart.count'=1;;;0; 'centreon4#service.tasks.restart.rate'=0;;;0; 'centreon1#service.tasks.problems.count'=0;;;0; 'centreon1#service.replica.count'=1;;;0; 'centreon1#service.tasks.count'=1;;;0; 'centreon1#service.tasks.running.count'=1;;;0; 'centreon1#service.tasks.shutdown.count'=0;;;0; 'centreon1#service.tasks.failed.count'=0;;;0; 'centreon1#service.tasks.restart.count'=0;;;0; 'centreon1#service.tasks.restart.rate'=0;;;0; 'centreon2#service.tasks.problems.count'=0;;;0; 'centreon2#service.replica.count'=3;;;0; 'centreon2#service.tasks.count'=2;;;0; 'centreon2#service.tasks.running.count'=2;;;0; 'centreon2#service.tasks.shutdown.count'=0;;;0; 'centreon2#service.tasks.failed.count'=0;;;0; 'centreon2#service.tasks.restart.count'=0;;;0; 'centreon2#service.tasks.restart.rate'=0;;;0; 'centreon3#service.tasks.problems.count'=0;;;0; 'centreon3#service.replica.count'=2;;;0; 'centreon3#service.tasks.count'=3;;;0; 'centreon3#service.tasks.running.count'=2;;;0; 'centreon3#service.tasks.shutdown.count'=0;;;0; 'centreon3#service.tasks.failed.count'=1;;;0;
    ...    2
    ...    --critical-task-status='' --critical-service-status=''
    ...    OK: All services running well | 'services.tasks.total.count'=8;;;0; 'services.tasks.problems.count'=1;;;0; 'centreon4#service.tasks.problems.count'=0;;;0; 'centreon4#service.replica.count'=2;;;0; 'centreon4#service.tasks.count'=2;;;0; 'centreon4#service.tasks.running.count'=1;;;0; 'centreon4#service.tasks.shutdown.count'=0;;;0; 'centreon4#service.tasks.failed.count'=0;;;0; 'centreon4#service.tasks.restart.count'=1;;;0; 'centreon4#service.tasks.restart.rate'=0;;;0; 'centreon1#service.tasks.problems.count'=0;;;0; 'centreon1#service.replica.count'=1;;;0; 'centreon1#service.tasks.count'=1;;;0; 'centreon1#service.tasks.running.count'=1;;;0; 'centreon1#service.tasks.shutdown.count'=0;;;0; 'centreon1#service.tasks.failed.count'=0;;;0; 'centreon1#service.tasks.restart.count'=0;;;0; 'centreon1#service.tasks.restart.rate'=0;;;0; 'centreon2#service.tasks.problems.count'=0;;;0; 'centreon2#service.replica.count'=3;;;0; 'centreon2#service.tasks.count'=2;;;0; 'centreon2#service.tasks.running.count'=2;;;0; 'centreon2#service.tasks.shutdown.count'=0;;;0; 'centreon2#service.tasks.failed.count'=0;;;0; 'centreon2#service.tasks.restart.count'=0;;;0; 'centreon2#service.tasks.restart.rate'=0;;;0; 'centreon3#service.tasks.problems.count'=0;;;0; 'centreon3#service.replica.count'=2;;;0; 'centreon3#service.tasks.count'=3;;;0; 'centreon3#service.tasks.running.count'=2;;;0; 'centreon3#service.tasks.shutdown.count'=0;;;0; 'centreon3#service.tasks.failed.count'=1;;;0;
    ...    3
    ...    --filter-service-name='centreon1'
    ...    OK: service 'centreon1' (123), Problems: 0, Desired replicas: 1, Running: 1, Shutdown: 0, Failed: 0 - service 'centreon1' task 'abc' state: running [node: 127.0.0.1 (node1)] [container: container1] [desired state: running] [message: started] | 'services.tasks.total.count'=1;;;0; 'services.tasks.problems.count'=0;;;0; 'centreon1#service.tasks.problems.count'=0;;;0; 'centreon1#service.replica.count'=1;;;0; 'centreon1#service.tasks.count'=1;;;0; 'centreon1#service.tasks.running.count'=1;;;0; 'centreon1#service.tasks.shutdown.count'=0;;;0; 'centreon1#service.tasks.failed.count'=0;;;0; 'centreon1#service.tasks.restart.count'=0;;;0; 'centreon1#service.tasks.restart.rate'=0;;;0;
    ...    4
    ...    --filter-service-name='centreon2'
    ...    CRITICAL: service 'centreon2' (456) | 'services.tasks.total.count'=2;;;0; 'services.tasks.problems.count'=0;;;0; 'centreon2#service.tasks.problems.count'=0;;;0; 'centreon2#service.replica.count'=3;;;0; 'centreon2#service.tasks.count'=2;;;0; 'centreon2#service.tasks.running.count'=2;;;0; 'centreon2#service.tasks.shutdown.count'=0;;;0; 'centreon2#service.tasks.failed.count'=0;;;0; 'centreon2#service.tasks.restart.count'=0;;;0; 'centreon2#service.tasks.restart.rate'=0;;;0;
    ...    5
    ...    --filter-service-name='centreon3'
    ...    CRITICAL: service 'centreon3' task 'mno' state: failed [node: 127.0.0.1 (node1)] [container: container1] [desired state: running] [message: failed] | 'services.tasks.total.count'=3;;;0; 'services.tasks.problems.count'=1;;;0; 'centreon3#service.tasks.problems.count'=0;;;0; 'centreon3#service.replica.count'=2;;;0; 'centreon3#service.tasks.count'=3;;;0; 'centreon3#service.tasks.running.count'=2;;;0; 'centreon3#service.tasks.shutdown.count'=0;;;0; 'centreon3#service.tasks.failed.count'=1;;;0;
    ...    6
    ...    --filter-service-name='centreon4'
    ...    CRITICAL: service 'centreon4' (101112) | 'services.tasks.total.count'=2;;;0; 'services.tasks.problems.count'=0;;;0; 'centreon4#service.tasks.problems.count'=0;;;0; 'centreon4#service.replica.count'=2;;;0; 'centreon4#service.tasks.count'=2;;;0; 'centreon4#service.tasks.running.count'=1;;;0; 'centreon4#service.tasks.shutdown.count'=0;;;0; 'centreon4#service.tasks.failed.count'=0;;;0; 'centreon4#service.tasks.restart.count'=1;;;0; 'centreon4#service.tasks.restart.rate'=0;;;0;
