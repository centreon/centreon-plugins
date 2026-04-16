*** Settings ***
Documentation       IPFabric plugin
Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ipfabric.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::ipfabric::plugin
...                 --api-key=EEECGFCGFCGF
...                 --mode=path-verification
...                 --hostname=${HOSTNAME}
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
PathVerification ${tc}
    [Tags]    apps    api    ipfabric
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                                        expected_result    --
            ...       1   ${EMPTY}                                                                             OK: Number of paths detected: 1020, mismatch: 0, all state: 0, part state: 0, none state: 1020, error state: 0 - All paths are ok | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...       2   --filter-src-ip=127.0.0.2                                                            OK: Number of paths detected: 1, mismatch: 0, all state: 0, part state: 0, none state: 1, error state: 0 - source 127.0.0.2:2222 destination 172.16.20.8:2222 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
            ...       3   --filter-dst-ip=127.0.0.3                                                            OK: Number of paths detected: 1, mismatch: 0, all state: 0, part state: 0, none state: 1, error state: 0 - source 10.10.1.15:2222 destination 127.0.0.3:2222 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
            ...       4   --filter-src-port=1234                                                               OK: Number of paths detected: 1, mismatch: 0, all state: 0, part state: 0, none state: 1, error state: 0 - source 10.10.1.15:1234 destination 172.16.20.8:2222 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
            ...       5   --filter-dst-port=4321                                                               OK: Number of paths detected: 1, mismatch: 0, all state: 0, part state: 0, none state: 1, error state: 0 - source 10.10.1.15:2222 destination 172.16.20.8:4321 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
            ...       6   --warning-paths-mismatch=1:                                                          WARNING: mismatch: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;1:;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...       7   --critical-paths-mismatch=1:                                                         CRITICAL: mismatch: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;1:;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...       8   --warning-paths-state-all=1:                                                         WARNING: all state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;1:;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...       9   --critical-paths-state-all=1:                                                        CRITICAL: all state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;1:;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...      10   --warning-paths-state-part=1:                                                        WARNING: part state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;1:;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...      11   --critical-paths-state-part=1:                                                       CRITICAL: part state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;1:;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...      12   --warning-paths-state-none=:1                                                        WARNING: none state: 1020 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;0:1;;0; 'paths.state.error.count'=0;;;0;
            ...      13   --critical-paths-state-none=:1                                                       CRITICAL: none state: 1020 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;0:1;0; 'paths.state.error.count'=0;;;0;
            ...      14   --warning-paths-state-error=1:                                                       WARNING: error state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;1:;;0;
            ...      15   --critical-paths-state-error=1:                                                      CRITICAL: error state: 0 | 'paths.detected.count'=1020;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;1:;0;
            ...      16   --warning-paths-detected=:500                                                        WARNING: Number of paths detected: 1020 | 'paths.detected.count'=1020;0:500;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...      17   --critical-paths-detected=:1000                                                      CRITICAL: Number of paths detected: 1020 | 'paths.detected.count'=1020;;0:1000;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1020;;;0; 'paths.state.error.count'=0;;;0;
            ...      18   --warning-status='\\\%{paths_state_error_count}>=0' --filter-src-ip='127.0.0.2'      WARNING: source 127.0.0.2:2222 destination 172.16.20.8:2222 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
            ...      19   --critical-status='\\\%{paths_state_error_count}>=0' --filter-src-ip='127.0.0.2'     CRITICAL: source 127.0.0.2:2222 destination 172.16.20.8:2222 [protocol: tcp] state: none [expected state: none] | 'paths.detected.count'=1;;;0; 'paths.mismatch.count'=0;;;0; 'paths.state.all.count'=0;;;0; 'paths.state.part.count'=0;;;0; 'paths.state.none.count'=1;;;0; 'paths.state.error.count'=0;;;0;
