*** Settings ***
Documentation       Hitachi E-Series local - mode efficiency

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::hitachi::eseries::local::plugin --instance-id=0123 --command-path=${CURDIR}${/}bin


*** Test Cases ***
efficiency ${tc}
    [Tags]    storage    hitachi    eseries    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=efficiency
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                  expected_result    --
        ...      1     ${EMPTY}                                       OK: Total Efficiency Ratio: 2.50, Data Reduction Ratio: 1.20, Software Saving Ratio: 1.30 | 'storage.efficiency.total.ratio'=2.50;2.01:;1.01:;0; 'storage.efficiency.data_reduction.ratio'=1.20;;;0; 'storage.efficiency.software_saving.ratio'=1.30;;;0;
        ...      2     --warning-total-efficiency-ratio=3:            WARNING: Total Efficiency Ratio: 2.50 | 'storage.efficiency.total.ratio'=2.50;3:;1.01:;0; 'storage.efficiency.data_reduction.ratio'=1.20;;;0; 'storage.efficiency.software_saving.ratio'=1.30;;;0;
        ...      3     --critical-total-efficiency-ratio=3:           CRITICAL: Total Efficiency Ratio: 2.50 | 'storage.efficiency.total.ratio'=2.50;2.01:;3:;0; 'storage.efficiency.data_reduction.ratio'=1.20;;;0; 'storage.efficiency.software_saving.ratio'=1.30;;;0;
        ...      4     --warning-data-reduction-ratio=2:              WARNING: Data Reduction Ratio: 1.20 | 'storage.efficiency.total.ratio'=2.50;2.01:;1.01:;0; 'storage.efficiency.data_reduction.ratio'=1.20;2:;;0; 'storage.efficiency.software_saving.ratio'=1.30;;;0;
        ...      5     --critical-software-saving-ratio=2:            CRITICAL: Software Saving Ratio: 1.30 | 'storage.efficiency.total.ratio'=2.50;2.01:;1.01:;0; 'storage.efficiency.data_reduction.ratio'=1.20;;;0; 'storage.efficiency.software_saving.ratio'=1.30;;2:;0;
