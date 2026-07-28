*** Settings ***
Documentation       apps::thales::mistral::vs9::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mistral-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::thales::mistral::vs9::restapi::plugin
...                 --mode=clusters
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=1
...                 --api-password=1


*** Test Cases ***
Clusters ${tc}
    [Tags]    apps    thales    restapi
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
    ...    OK: All clusters are ok | 'clusters.detected.count'=2;;;0;
    ...    2
    ...    --filter-cluster-name=ANO-8
    ...    OK: cluster 'HAC-ANO-8' virtual ip: 10.10.100.10/24, timeToSwitch: 3 s - status: HAC_OPERATIONAL, available for switching: yes - members are ok | 'clusters.detected.count'=1;;;0;
    ...    3
    ...    --unknown-cluster-status=1
    ...    UNKNOWN: cluster 'HAC-ANO-8' status: HAC_OPERATIONAL, available for switching: yes - cluster 'HAC_ANO-2' status: HAC_OPERATIONAL, available for switching: yes | 'clusters.detected.count'=2;;;0;
    ...    4
    ...    --warning-cluster-status=1
    ...    WARNING: cluster 'HAC-ANO-8' status: HAC_OPERATIONAL, available for switching: yes - cluster 'HAC_ANO-2' status: HAC_OPERATIONAL, available for switching: yes | 'clusters.detected.count'=2;;;0;
    ...    5
    ...    --critical-cluster-status=1
    ...    CRITICAL: cluster 'HAC-ANO-8' status: HAC_OPERATIONAL, available for switching: yes - cluster 'HAC_ANO-2' status: HAC_OPERATIONAL, available for switching: yes | 'clusters.detected.count'=2;;;0;
    ...    6
    ...    --unknown-member-status=1
    ...    UNKNOWN: cluster 'HAC-ANO-8' member 'ano-3' connected status: connected [role: backup] - member 'ano-6' connected status: connected [role: master] - cluster 'HAC_ANO-2' member 'ano-1' connected status: connected [role: backup] - member 'ano-3' connected status: connected [role: master] | 'clusters.detected.count'=2;;;0;
    ...    7
    ...    --warning-member-status='\\\%{connectedStatus} =~ /connected/'
    ...    WARNING: cluster 'HAC-ANO-8' member 'ano-3' connected status: connected [role: backup] - member 'ano-6' connected status: connected [role: master] - cluster 'HAC_ANO-2' member 'ano-1' connected status: connected [role: backup] - member 'ano-3' connected status: connected [role: master] | 'clusters.detected.count'=2;;;0;
    ...    8
    ...    --critical-member-status='\\\%{connectedStatus} =~ /connected/'
    ...    CRITICAL: cluster 'HAC-ANO-8' member 'ano-3' connected status: connected [role: backup] - member 'ano-6' connected status: connected [role: master] - cluster 'HAC_ANO-2' member 'ano-1' connected status: connected [role: backup] - member 'ano-3' connected status: connected [role: master] | 'clusters.detected.count'=2;;;0;
    ...    9
    ...    --warning-clusters-detected=1
    ...    WARNING: Number of clusters detected: 2 | 'clusters.detected.count'=2;0:1;;0;
    ...    10
    ...    --critical-clusters-detected=1
    ...    CRITICAL: Number of clusters detected: 2 | 'clusters.detected.count'=2;;0:1;0;
