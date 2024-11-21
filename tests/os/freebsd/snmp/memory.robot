*** Settings ***
Documentation       Check memory table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::freebsd::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/freebsd/snmp/freebsd
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     ${EMPTY}                        OK: Ram Total: 7.85 GB, Used (-cache): 692.32 MB (8.62%), Cached: 197.17 MB | 'cached'=206745600B;;;0; 'used'=725950464B;;;0;8424431616
            ...      2     --warning='1'                   WARNING: Ram Total: 7.85 GB, Used (-cache): 692.32 MB (8.62%), Cached: 197.17 MB | 'cached'=206745600B;;;0; 'used'=725950464B;0:84244316;;0;8424431616
            ...      3     --critical='1'                  CRITICAL: Ram Total: 7.85 GB, Used (-cache): 692.32 MB (8.62%), Cached: 197.17 MB | 'cached'=206745600B;;;0; 'used'=725950464B;;0:84244316;0;8424431616
            ...      4     --swap                          OK: Ram Total: 7.85 GB, Used (-cache): 692.32 MB (8.62%), Cached: 197.17 MB - Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'cached'=206745600B;;;0; 'used'=725950464B;;;0;8424431616 'swap'=0B;;;0;2147352576
            ...      6     --swap --warning-swap='-2:-1'   WARNING: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'cached'=206745600B;;;0; 'used'=725950464B;;;0;8424431616 'swap'=0B;-42947051:-21473525;;0;2147352576
            ...      7     --swap --critical-swap='-2:-1'  CRITICAL: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'cached'=206745600B;;;0; 'used'=725950464B;;;0;8424431616 'swap'=0B;;-42947051:-21473525;0;2147352576
            ...      8     --no-swap                       OK: Ram Total: 7.85 GB, Used (-cache): 692.32 MB (8.62%), Cached: 197.17 MB | 'cached'=206745600B;;;0; 'used'=725950464B;;;0;8424431616