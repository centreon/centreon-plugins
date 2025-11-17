*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=licenses --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
Licenses ${tc}
    [Tags]    network    hp    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: All licenses are ok | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       2   --unknown-license-status='%\\{status\\} eq "valid"'                      UNKNOWN: License 'ausf' status: valid - License 'eir' status: valid - License 'nrf' status: valid - License 'smsf' status: valid - License 'udm' status: valid - License 'udr' status: valid | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       3   --warning-license-status='%\\{status\\} eq "valid"'                      WARNING: License 'ausf' status: valid - License 'eir' status: valid - License 'nrf' status: valid - License 'smsf' status: valid - License 'udm' status: valid - License 'udr' status: valid | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       4   --critical-license-status='%\\{status\\} eq "valid"'                     CRITICAL: License 'ausf' status: valid - License 'eir' status: valid - License 'nrf' status: valid - License 'smsf' status: valid - License 'udm' status: valid - License 'udr' status: valid | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       5   --warning-licenses-detected=0                                            WARNING: detected: 6 | 'licenses.detected.count'=6;0:0;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       6   --critical-licenses-detected=0                                           CRITICAL: detected: 6 | 'licenses.detected.count'=6;;0:0;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       7   --warning-licenses-valid=0                                               WARNING: valid: 6 | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;0:0;;0;6 'licenses.invalid.count'=0;;;0;6
            ...       8   --critical-licenses-valid=0                                              CRITICAL: valid: 6 | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;0:0;0;6 'licenses.invalid.count'=0;;;0;6
            ...       9   --warning-licenses-invalid=1:                                            WARNING: invalid: 0 | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;1:;;0;6
            ...      10   --critical-licenses-invalid=1:                                           CRITICAL: invalid: 0 | 'licenses.detected.count'=6;;;0; 'licenses.valid.count'=6;;;0;6 'licenses.invalid.count'=0;;1:;0;6
