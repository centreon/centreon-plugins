*** Settings ***
Documentation       Check Rubrik REST API authentication

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}applications-rubrik-restapi.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto=http
...                 --mode=disks
...                 --port=${APIPORT}


*** Test Cases ***
jobs ${tc}/11
    [Tags]    apps    backup    rubrik    restapi    jobs

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc     extraoptions            expected_result   --
        ...      1      ${EMPTY}                                                                             UNKNOWN: Need to specify either --service-account or --api-username/--api-password option.
        ...      2      --service-account='client:12345' --secret='secret'                                   OK
        ...      3      --service-account='client:12345' --secret='secret' --use-cdm-authent                 OK
