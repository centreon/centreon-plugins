*** Settings ***
Documentation       Hitachi E-Series local - mode path-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::hitachi::eseries::local::plugin --command-path=${CURDIR}${/}bin


*** Test Cases ***
path-status ${tc}
    [Tags]    storage    hitachi    eseries    local    path
    ${command}    Catenate
    ...    ${CMD}
    ...    --instance-id=0123
    ...    --mode=path-status
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                     expected_result    --
        ...      1     ${EMPTY}                                                          CRITICAL: Path 'CL2-A:1' Status: BLK
        ...      2     --include-port=CL1-A                                              OK: All paths are normal
        ...      3     --exclude-port=CL2-A                                              OK: All paths are normal
        ...      4     --include-lun=0                                                   OK: All paths are normal
        ...      5     --exclude-lun=0                                                   CRITICAL: Path 'CL2-A:1' Status: BLK
        ...      6     --warning-status='\\\%{status} eq "NML"' --critical-status=''     WARNING: Path 'CL1-A:0' Status: NML - Path 'CL1-A:1' Status: NML - Path 'CL2-A:0' Status: NML
        ...      7     --critical-status='\\\%{status} eq "BLK"'                         CRITICAL: Path 'CL2-A:1' Status: BLK
