*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
configuration ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=configuration
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     --verbose                                                                        CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      2     --warning-status='\\\%{running_last_changed}'                                    CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      3     --critical-status='\\\%{running_last_changed} > \\\%{running_last_saved}'        CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      4     --verbose                                                                        CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      5     --warning-status='\\\%{running_last_saved}'                                      CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      6     --critical-status='\\\%{running_last_saved} > \\\%{running_last_changed}'        OK: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      7     --warning-status='\\\%{startup_last_changed}'                                    CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
            ...      8     --critical-status='\\\%{startup_last_changed}'                                   CRITICAL: Configuration Running Last Changed: 1y 4M 1d 37m 12s, Running Last Saved: 2w 5d 16h 13m 30s, Startup Last Changed: 1w 4d 16h 40m 29s | 'running_last_changed'=42164530s;;;0; 'running_last_saved'=1700010s;;;0; 'startup_last_changed'=1010429s;;;0;
