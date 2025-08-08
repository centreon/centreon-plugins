*** Settings ***
Documentation       Juniper Mseries Netconf LSP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=lsp
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}lsp.netconf"

*** Test Cases ***
Lsp ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    CRITICAL: LSP session 'FROM-MX1-TO-MX3' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.3] state: Dn | 'lsp.sessions.detected.count'=3;;;0;
            ...    2    --filter-type=Egress
            ...    OK: LSP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] state: Up | 'lsp.sessions.detected.count'=1;;;0;
            ...    3    --filter-name=FROM-MX2-TO-MX1
            ...    OK: LSP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] state: Up | 'lsp.sessions.detected.count'=1;;;0;
            ...    4    --filter-type=Egress --unknown-status='\\\%{srcAddress}=10.0.0.2'
            ...    UNKNOWN: LSP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] state: Up | 'lsp.sessions.detected.count'=1;;;0;
            ...    5    --filter-type=Egress --warning-status='\\\%{dstAddress}=10.0.0.1'
            ...    WARNING: LSP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] state: Up | 'lsp.sessions.detected.count'=1;;;0;
            ...    6    --filter-type=Egress --critical-status='\\\%{lspState} eq "Up"'
            ...    CRITICAL: LSP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] state: Up | 'lsp.sessions.detected.count'=1;;;0;
            ...    7    --filter-type=Egress --warning-lsp-sessions-detected=0
            ...    WARNING: Number of LSP sessions detected: 1 | 'lsp.sessions.detected.count'=1;0:0;;0;
            ...    8    --filter-type=Egress --critical-lsp-sessions-detected=0
            ...    CRITICAL: Number of LSP sessions detected: 1 | 'lsp.sessions.detected.count'=1;;0:0;0;
