*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=upf --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
UPF (User Plane Function) ${tc}
    [Tags]    network    hp    api


    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                   expected_result    --
            ...       1   ${EMPTY}                                                        OK: Number of sessions: 26, GTP-U interfaces: 4, IP interfaces: 2, DNN: 1 - All PFCP nodes are ok | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       2   --unknown-upf-pfcp-node-status='%\\{status\\} eq "up"'          UNKNOWN: PFCP local IP '172.42.2.8' remote IP '172.42.2.10' status: up - PFCP local IP '172.42.2.8' remote IP '172.42.2.9' status: up | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       3   --warning-upf-pfcp-node-status='%\\{status\\} eq "up"'          WARNING: PFCP local IP '172.42.2.8' remote IP '172.42.2.10' status: up - PFCP local IP '172.42.2.8' remote IP '172.42.2.9' status: up | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       4   --critical-upf-pfcp-node-status='%\\{status\\} eq "up"'         CRITICAL: PFCP local IP '172.42.2.8' remote IP '172.42.2.10' status: up - PFCP local IP '172.42.2.8' remote IP '172.42.2.9' status: up | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       5   --warning-upf-fpcf-nodes-detected=1                             WARNING: Number of fpcf nodes detected: 2 | 'upf.pfcp.nodes.detected.count'=2;0:1;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       6   --critical-upf-fpcf-nodes-detected=1                            CRITICAL: Number of fpcf nodes detected: 2 | 'upf.pfcp.nodes.detected.count'=2;;0:1;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       7   --warning-upf-sessions=1                                        WARNING: Number of sessions: 26 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;0:1;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       8   --critical-upf-sessions=1                                       CRITICAL: Number of sessions: 26 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;0:1;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...       9   --warning-upf-gtpu-interfaces=1                                 WARNING: Number of GTP-U interfaces: 4 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;0:1;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...      10   --critical-upf-gtpu-interfaces=1                                CRITICAL: Number of GTP-U interfaces: 4 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;0:1;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;;0;
            ...      11   --warning-upf-ip-interfaces=1                                   WARNING: Number of IP interfaces: 2 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;0:1;;0; 'upf.dnn.count'=1;;;0;
            ...      12   --critical-upf-ip-interfaces=1                                  CRITICAL: Number of IP interfaces: 2 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;0:1;0; 'upf.dnn.count'=1;;;0;
            ...      13   --warning-upf-dnn=0                                             WARNING: Number of DNN: 1 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;0:0;;0;
            ...      14   --critical-upf-dnn=0                                            CRITICAL: Number of DNN: 1 | 'upf.pfcp.nodes.detected.count'=2;;;0; 'upf.sessions.count'=26;;;0; 'upf.gtpu.interfaces.count'=4;;;0; 'upf.ip.interfaces.count'=2;;;0; 'upf.dnn.count'=1;;0:0;0;
