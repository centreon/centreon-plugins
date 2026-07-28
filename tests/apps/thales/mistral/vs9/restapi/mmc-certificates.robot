*** Settings ***
Documentation       apps::thales::mistral::vs9::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mistral-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::thales::mistral::vs9::restapi::plugin
...                 --mode=mmc-certificates
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=1
...                 --api-password=1


*** Test Cases ***
Mmc-certificates ${tc}
    [Tags]    apps    thales    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: all certificates are ok \\\| '987654321~extra-b.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; '989898989898~mmc-base.local~ITSME_VS1-A#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefg~extra.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefgh~COMMON-RMGT~AC_ROOT#certificate.expires.seconds'=\\\\d+s;;;0;
    ...    2
    ...    --time-certificate-unit=m
    ...    OK: all certificates are ok \\\| '987654321~extra-b.local~NONE_VS1-RMGT#certificate.expires.minutes'=\\\\d+m;;;0; '989898989898~mmc-base.local~ITSME_VS1-A#certificate.expires.minutes'=\\\\d+m;;;0; 'abcdefg~extra.local~NONE_VS1-RMGT#certificate.expires.minutes'=\\\\d+m;;;0; 'abcdefgh~COMMON-RMGT~AC_ROOT#certificate.expires.minutes'=\\\\d+m;;;0
    ...    3
    ...    --filter-cert-inactive=1
    ...    OK: all certificates are ok \\\| '987654321~extra-b.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; '989898989898~mmc-base.local~ITSME_VS1-A#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefg~extra.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefgh~COMMON-RMGT~AC_ROOT#certificate.expires.seconds'=\\\\d+s;;;0;
    ...    4
    ...    --filter-cert-revoked=1
    ...    OK: all certificates are ok \\\| '987654321~extra-b.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; '989898989898~mmc-base.local~ITSME_VS1-A#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefg~extra.local~NONE_VS1-RMGT#certificate.expires.seconds'=\\\\d+s;;;0; 'abcdefgh~COMMON-RMGT~AC_ROOT#certificate.expires.seconds'=\\\\d+s;;;0;
    ...    5
    ...    --unknown-certificate-status=1
    ...    UNKNOWN: certificate 'abcdefgh' \\\\[subject: COMMON-RMGT, issuer: AC_ROOT, usages: RMGT_AUTH]
    ...    6
    ...    --warning-certificate-status=1
    ...    WARNING: certificate 'abcdefgh' \\\\[subject: COMMON-RMGT, issuer: AC_ROOT, usages: RMGT_AUTH]
    ...    7
    ...    --critical-certificate-status=1
    ...    CRITICAL: certificate 'abcdefgh' \\\\[subject: COMMON-RMGT, issuer: AC_ROOT, usages: RMGT_AUTH]
    ...    8
    ...    --warning-certificate-expires=1
    ...    WARNING: certificate '987654321' \\\\[subject: extra-b.local, issuer: NONE_VS1-RMGT, usages: RMGT_AUTH]
    ...    9
    ...    --critical-certificate-expires=1
    ...    CRITICAL: certificate '987654321' \\\\[subject: extra-b.local, issuer: NONE_VS1-RMGT, usages: RMGT_AUTH]
