*** Settings ***
Documentation       apps::backup::rubrik::graphql::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}rubrik-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::graphql::plugin
...                 --mode=nodes
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Nodes ${tc}
    [Tags]    apps    backup    graphql
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
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    3
    ...    --last=99999m
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    4
    ...    --include-node-id=ODSIOIODS
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=0;;;0; 'TEST-IN#cluster.nodes.ok.count'=0;;;0;0
    ...    5
    ...    --exclude-node-id=ODSIOIODS
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=0;;;0; 'TEST-VI#cluster.nodes.ok.count'=0;;;0;0 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    6
    ...    --unknown-nodes-status='\\\%{status} =~ /ok/'
    ...    UNKNOWN: Cluster 'TEST-VI' Node 'ODSIOIODS' status: ok - Cluster 'TEST-IN' Node 'OSDIOSDDS' status: ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    7
    ...    --warning-nodes-status='\\\%{status} =~ /ok/'
    ...    WARNING: Cluster 'TEST-VI' Node 'ODSIOIODS' status: ok - Cluster 'TEST-IN' Node 'OSDIOSDDS' status: ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    8
    ...    --critical-nodes-status='\\\%{status} =~ /ok/'
    ...    CRITICAL: Cluster 'TEST-VI' Node 'ODSIOIODS' status: ok - Cluster 'TEST-IN' Node 'OSDIOSDDS' status: ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    9
    ...    --warning-cluster-nodes-total=:0
    ...    WARNING: Cluster 'TEST-VI' node total: 1 - Cluster 'TEST-IN' node total: 1 | 'TEST-VI#cluster.nodes.total.count'=1;0:0;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;0:0;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    10
    ...    --critical-cluster-nodes-total=:0
    ...    CRITICAL: Cluster 'TEST-VI' node total: 1 - Cluster 'TEST-IN' node total: 1 | 'TEST-VI#cluster.nodes.total.count'=1;;0:0;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;0:0;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
    ...    11
    ...    --warning-cluster-nodes-ok=:0
    ...    WARNING: Cluster 'TEST-VI' node ok: 1 - Cluster 'TEST-IN' node ok: 1 | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;0:0;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;0:0;;0;1
    ...    12
    ...    --critical-cluster-nodes-ok=:0
    ...    CRITICAL: Cluster 'TEST-VI' node ok: 1 - Cluster 'TEST-IN' node ok: 1 | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;0:0;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;0:0;0;1
    ...    13
    ...    --include-cluster=azzaza-6zaza-zzaf-zaza-3332
    ...    OK: Cluster 'TEST-VI' Node 'ODSIOIODS' status: ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1
    ...    14
    ...    --exclude-cluster=TEST-IN
    ...    OK: All nodes are ok | 'TEST-VI#cluster.nodes.total.count'=1;;;0; 'TEST-VI#cluster.nodes.ok.count'=1;;;0;1 'TEST-IN#cluster.nodes.total.count'=1;;;0; 'TEST-IN#cluster.nodes.ok.count'=1;;;0;1
