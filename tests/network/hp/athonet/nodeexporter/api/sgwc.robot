*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=sgwc --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
SGWC (Serving GateWay Control plane function) ${tc}
    [Tags]    network    hp    api


    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: Number of UE: 13, default bearers: 13 - PFCP local IP '172.42.2.10' remote IP '172.42.2.8' status: up - All GTP-C connections are ok - Peer remote IP '172.42.2.8' target type 'sgwc' is blacklisted: no | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       2   --unknown-pfcp-node-status='%\\{status\\} ne "running"'                  UNKNOWN: PFCP local IP '172.42.2.10' remote IP '172.42.2.8' status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       3   --warning-pfcp-node-status='%\\{status\\} ne "running"'                  WARNING: PFCP local IP '172.42.2.10' remote IP '172.42.2.8' status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       4   --critical-pfcp-node-status='%\\{status\\} ne "running"'                 CRITICAL: PFCP local IP '172.42.2.10' remote IP '172.42.2.8' status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       5   --unknown-gtpc-connection-status='%\\{status\\} ne "running"'            UNKNOWN: GTP-C local IP '172.42.2.0' remote IP '172.42.2.1' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.20.8.20' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.42.9.20' connection status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       6   --warning-gtpc-connection-status='%\\{status\\} ne "running"'            WARNING: GTP-C local IP '172.42.2.0' remote IP '172.42.2.1' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.20.8.20' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.42.9.20' connection status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       7   --critical-gtpc-connection-status='%\\{status\\} ne "running"'           CRITICAL: GTP-C local IP '172.42.2.0' remote IP '172.42.2.1' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.20.8.20' connection status: up - GTP-C local IP '172.42.9.35' remote IP '172.42.9.20' connection status: up | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       8   --unknown-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'           UNKNOWN: Peer remote IP '172.42.2.8' target type 'sgwc' is blacklisted: no | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       9   --warning-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'           WARNING: Peer remote IP '172.42.2.8' target type 'sgwc' is blacklisted: no | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      10   --critical-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'          CRITICAL: Peer remote IP '172.42.2.8' target type 'sgwc' is blacklisted: no | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      11   --warning-ue=1                                                           WARNING: Number of UE: 13 | 'sgwc.ue.count'=13;0:1;;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      12   --critical-ue=1                                                          CRITICAL: Number of UE: 13 | 'sgwc.ue.count'=13;;0:1;0; 'sgwc.dfb.count'=13;;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      13   --warning-dfb=1                                                          WARNING: Number of default bearers: 13 | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;0:1;;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      14   --critical-dfb=1                                                         CRITICAL: Number of default bearers: 13 | 'sgwc.ue.count'=13;;;0; 'sgwc.dfb.count'=13;;0:1;0; 'sgwc~172.42.2.8#peer.blacklisted.count'=0;;;0;
