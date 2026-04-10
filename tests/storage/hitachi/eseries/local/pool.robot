*** Settings ***
Documentation       Hitachi E-Series local - mode pool

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::hitachi::eseries::local::plugin --baie-id=0123 --command-path=${CURDIR}${/}bin


*** Test Cases ***
pool ${tc}
    [Tags]    storage    hitachi    eseries    local    pool
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=pool
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                           expected_result    --
        ...      1     ${EMPTY}                                                                CRITICAL: Pool '001' Status: POLF | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      2     --include-pid=000                                                       OK: Pool '000' Status: POLN, Usage - Total: 400.00 GB Used: 200.00 GB (50.0%) Free: 200.00 GB (50.0%), Usage: 50.0% | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100
        ...      3     --exclude-pid=000                                                       CRITICAL: Pool '001' Status: POLF | '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      4     --warning-status='\\\%{status} eq "POLN"' --critical-status=''          WARNING: Pool '000' Status: POLN | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      5     --critical-status='\\\%{status} eq "POLF"'                              CRITICAL: Pool '001' Status: POLF | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      6     --critical-status='' --warning-usage=:45                                WARNING: Pool '000' Usage - Total: 400.00 GB Used: 200.00 GB (50.0%) Free: 200.00 GB (50.0%) - Pool '001' Usage - Total: 400.00 GB Used: 392.00 GB (98.0%) Free: 8.00 GB (2.0%) | '000#storage.pool.space.usage.bytes'=214748364800B;0:45;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;0:45;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      7     --critical-status='' --critical-usage=:45                               CRITICAL: Pool '000' Usage - Total: 400.00 GB Used: 200.00 GB (50.0%) Free: 200.00 GB (50.0%) - Pool '001' Usage - Total: 400.00 GB Used: 392.00 GB (98.0%) Free: 8.00 GB (2.0%) | '000#storage.pool.space.usage.bytes'=214748364800B;;0:45;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;0:45;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;;0;100
        ...      8     --critical-status='' --warning-usage-prct=:45                           WARNING: Pool '000' Usage: 50.0% - Pool '001' Usage: 98.0% | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;0:45;;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;0:45;;0;100
        ...      9     --critical-status='' --critical-usage-prct=:45                          CRITICAL: Pool '000' Usage: 50.0% - Pool '001' Usage: 98.0% | '000#storage.pool.space.usage.bytes'=214748364800B;;;0;429496729600 '000#storage.pool.space.usage.percentage'=50.0%;;0:45;0;100 '001#storage.pool.space.usage.bytes'=420906795008B;;;0;429496729600 '001#storage.pool.space.usage.percentage'=98.0%;;0:45;0;100
