*** Settings ***
Documentation       Check the backup status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}keysight.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::keysight::nvos::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
ports ${tc}
    [Documentation]    Check the backups status
    [Tags]    network    backbox    restapi    backup
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=license
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                                                                    expected_result    --
            ...       1     --verbose --help                                                                                OK: All ports are ok | 'P14#port.traffic.out.percentage'=0.00%;;;0;100 'P17#port.traffic.out.percentage'=0.00%;;;0;100 checking port 'P01' license status: valid link operational status: up [admin: enabled] checking port 'P12' license status: valid link operational status: up [admin: enabled] checking port 'P14' license status: valid link operational status: up [admin: enabled] traffic out: 0.00%, traffic-out : Buffer creation packets packets-out : Buffer creation, packets-dropped : Buffer creation, packets-pass : Buffer creation, packets-insp : Buffer creation checking port 'P17' license status: valid link operational status: up [admin: enabled] traffic out: 0.00%, traffic-out : Buffer creation packets packets-out : Buffer creation, packets-dropped : Buffer creation, packets-pass : Buffer creation, packets-insp : Buffer creation
            ...       2     --filter-name                                                                                   ll