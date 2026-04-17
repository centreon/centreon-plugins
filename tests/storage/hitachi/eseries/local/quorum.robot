*** Settings ***
Documentation       Hitachi E-Series local - mode quorum

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::hitachi::eseries::local::plugin --instance-id=0123 --command-path=${CURDIR}${/}bin


*** Test Cases ***
quorum ${tc}
    [Tags]    storage    hitachi    eseries    local    quorum
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=quorum
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                       expected_result    --
        ...      1     ${EMPTY}                                                            CRITICAL: Quorum '1' Status: ERROR
        ...      2     --quorum-id=0                                                       OK: Quorum '0' Status: NORMAL
        ...      3     --quorum-id=1                                                       CRITICAL: Quorum '1' Status: ERROR
        ...      4     --warning-status='\\\%{status} ne "NORMAL"' --critical-status=''    WARNING: Quorum '1' Status: ERROR
        ...      5     --critical-status='\\\%{status} eq "NORMAL"'                        CRITICAL: Quorum '0' Status: NORMAL
