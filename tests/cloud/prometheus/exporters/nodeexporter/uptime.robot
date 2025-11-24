*** Settings ***
Documentation       Prometheus Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=uptime --hostname=${HOSTNAME} --port=${APIPORT}



*** Test Cases ***
Uptime ${tc}
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                         expected_result    --
            ...       1   ${EMPTY}                              OK: System uptime is: 40d 17h 22m 25s | 'system.uptime.seconds'=3518545;;;0;
            ...       2   --warning-uptime=1                    WARNING: System uptime is: 40d 17h 22m 25s | 'system.uptime.seconds'=3518545;0:1;;0;
            ...       3   --critical-uptime=1                   CRITICAL: System uptime is: 40d 17h 22m 25s | 'system.uptime.seconds'=3518545;;0:1;0;
            ...       4   --unit=m                              OK: System uptime is: 40d 17h 22m 25s | 'system.uptime.minutes'=58642;;;0;
            ...       5   --unit=m --warning-uptime=1           WARNING: System uptime is: 40d 17h 22m 25s | 'system.uptime.minutes'=58642;0:1;;0;
            ...       6   --unit=m --critical-uptime=1          CRITICAL: System uptime is: 40d 17h 22m 25s | 'system.uptime.minutes'=58642;;0:1;0;
            ...       7   --unit=h ${EMPTY}                     OK: System uptime is: 40d 17h 22m 25s | 'system.uptime.hours'=977;;;0;
            ...       8   --unit=h --warning-uptime=1           WARNING: System uptime is: 40d 17h 22m 25s | 'system.uptime.hours'=977;0:1;;0;
            ...       9   --unit=h --critical-uptime=1          CRITICAL: System uptime is: 40d 17h 22m 25s | 'system.uptime.hours'=977;;0:1;0;
            ...      10   --unit=d ${EMPTY}                     OK: System uptime is: 40d 17h 22m 25s | 'system.uptime.days'=40;;;0;
            ...      11   --unit=d --warning-uptime=1           WARNING: System uptime is: 40d 17h 22m 25s | 'system.uptime.days'=40;0:1;;0;
            ...      12   --unit=d --critical-uptime=1          CRITICAL: System uptime is: 40d 17h 22m 25s | 'system.uptime.days'=40;;0:1;0;
            ...      13   --unit=w ${EMPTY}                     OK: System uptime is: 40d 17h 22m 25s | 'system.uptime.weeks'=5;;;0;
            ...      14   --unit=w --warning-uptime=1           WARNING: System uptime is: 40d 17h 22m 25s | 'system.uptime.weeks'=5;0:1;;0;
            ...      15   --unit=w --critical-uptime=1          CRITICAL: System uptime is: 40d 17h 22m 25s | 'system.uptime.weeks'=5;;0:1;0;
