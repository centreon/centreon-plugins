*** Settings ***

# In this test we only check that connector can be loaded with any Redis module version

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

Test Timeout        120s


*** Variables ***
${INJECT_PERL_REDIS_1_999}     -Mredis_1_999 -I${CURDIR}
${INJECT_PERL_REDIS_2_000}     -Mredis_2_000 -I${CURDIR}
${CMD}             ${CENTREON_PLUGINS} --plugin=database::redis::plugin
...                --custommode=perlmod
...                --server=localhost
...                --username=UzEr
...                --password=P@sSw@rDZ
...                --mode=cpu

*** Test Cases ***
redis_v1.999 ${tc}
    [Tags]    database   redis

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL_REDIS_1_999} ${OLD_PERL5OPT}

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}
    Examples:        tc    extra_options                             expected_result    --
            ...      1     ${EMPTY}                                  UNKNOWN: Use of --username requires Perl Redis module v2.0 or higher but 1.999 was found

    Set Environment Variable    PERL5OPT    ${OLD_PERL5OPT}

redis_v2.000 ${tc}
    [Tags]    database   redis

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL_REDIS_2_000}

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}
    Examples:        tc    extra_options                             expected_result    --
            ...      1     ${EMPTY}                                  OK: CPU usage sys : skipped (no value(s)), user : skipped (no value(s)), sys-children : skipped (no value(s)), user-children : skipped (no value(s))

    Set Environment Variable    PERL5OPT    ${OLD_PERL5OPT}
