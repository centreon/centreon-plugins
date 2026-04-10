*** Settings ***
Documentation       Hitachi E-Series local - mode pair-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::hitachi::eseries::local::plugin --command-path=${CURDIR}${/}bin

*** Test Cases ***
pair-status ${tc}
    [Tags]    storage    hitachi    eseries    local    pair
    ${command}    Catenate
    ...    ${CMD}
    ...    --baie-id=0123
    ...    --mode=pair-status
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                             expected_result    --
        ...      1     ${EMPTY}                                  UNKNOWN: Please set --group-id option.
        ...      2     --group-id=GRP1                           CRITICAL: Pair 'GRP1 - GRP1-PAIR02' Status (L/R): COPY/COPY (sync: 50%/50%)
        ...      3     --group-id=GRP2                           OK: Pair 'GRP2 - GRP2-PAIR01' Status (L/R): PAIR/PAIR (sync: 100%/100%)
        ...      4     --group-id=GRP1 --ldev-id=GRP1-PAIR01     OK: Pair 'GRP1 - GRP1-PAIR01' Status (L/R): PAIR/PAIR (sync: 100%/100%)
        ...      5     --group-id=GRP1 --ldev-id=NONE            UNKNOWN: No pair found.
        ...      6     --mode=pair-status --group-id=GRPERR      CRITICAL: Pair 'GRPERR - GRPERR-PAIR01' Status (L/R): PSUE/PSUE (sync: 0%/0%)
        ...      7     --group-id=GRP2 --remote-baie-id=+10      OK: Pair 'GRP2 - GRP2-PAIR01' Status (L/R): PAIR/PAIR (sync: 100%/100%)
