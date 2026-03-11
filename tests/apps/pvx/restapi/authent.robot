*** Settings ***
Documentation       Check Accedian Skylight (previously PVX) authentication

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}pvx-mockoon.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::pvx::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --mode=http-hits


*** Test Cases ***
authent ${tc}/1
    [Tags]    apps    backup    rubrik    restapi    cache

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:     tc    extra_options                                                         expected_result    --
    ...           1     ${EMPTY}                                                              UNKNOWN: You must provide either username/password or an API key.
    ...           2     --api-key=R@X@R                                                       OK: All metrics are ok | 'ratio_application'=0.96;;;0; 'hits_error_application'=5.000hits/s;;;0; 'hits_application'=120.000hits/s;;;0; 'ratio_network'=0.98;;;0; 'hits_error_network'=2.000hits/s;;;0; 'hits_network'=95.000hits/s;;;0;
    ...           3     --username='username' --password='password' --use-auth-service=1      UNKNOWN: 401 Unauthorized
    ...           4     --username='Us3rN@m3' --password='password' --use-auth-service=1      OK: All metrics are ok | 'ratio_application'=0.96;;;0; 'hits_error_application'=5.000hits/s;;;0; 'hits_application'=120.000hits/s;;;0; 'ratio_network'=0.98;;;0; 'hits_error_network'=2.000hits/s;;;0; 'hits_network'=95.000hits/s;;;0;

