*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=cpu
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22

*** Test Cases ***
Cpu with curl ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                        expected_result   --
        ...      1     ${EMPTY}                                            OK: usage-percentage : skipped (no value(s)), usage-frequency : skipped (no value(s)) - no data for host host-22 counter cpu.capacity.provisioned.HOST at the moment.
        ...      2     ${EMPTY}                                            OK: CPU average usage is 9.16 %, used frequency is 4603.44 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000
        ...      3     --add-contention                                    OK: CPU average usage is 9.16 %, used frequency is 4603.44 kHz - CPU average contention is 0.00 %, contention frequency is 0.55 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;;;0;100 'cpu.capacity.contention.hertz'=550Hz;;;;50280000
        ...      4     --add-demand                                        OK: CPU average usage is 9.16 %, used frequency is 4603.44 kHz - CPU average demand is 8.36 %, demand frequency is 4201 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;;;; 'cpu.capacity.demand.hertz'=4201000Hz;;;;50280000
        ...      5     --add-corecount                                     OK: CPU average usage is 9.16 %, used frequency is 4603.44 kHz - CPU cores used: 83 | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.corecount.usage.count'=83;;;;
        ...      6     --add-contention --add-demand --add-corecount       OK: CPU average usage is 9.16 %, used frequency is 4603.44 kHz - CPU average contention is 0.00 %, contention frequency is 0.55 kHz - CPU average demand is 8.36 %, demand frequency is 4201 kHz - CPU cores used: 83 | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;;;0;100 'cpu.capacity.contention.hertz'=550Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;;;; 'cpu.capacity.demand.hertz'=4201000Hz;;;;50280000 'cpu.corecount.usage.count'=83;;;;
        ...      7     --warning-usage-percentage=5                        WARNING: CPU average usage is 9.16 % | 'cpu.capacity.usage.percentage'=9.16%;0:5;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000
        ...      8     --critical-usage-percentage=5                       CRITICAL: CPU average usage is 9.16 % | 'cpu.capacity.usage.percentage'=9.16%;;0:5;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000
        ...      9     --warning-usage-frequency=5                         WARNING: used frequency is 4603.44 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;0:5;;;50280000
        ...      10    --critical-usage-frequency=5                        CRITICAL: used frequency is 4603.44 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;0:5;;50280000
        ...      11    --warning-demand-percentage=5                       WARNING: CPU average demand is 8.36 % | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;0:5;;; 'cpu.capacity.demand.hertz'=4201000Hz;;;;50280000
        ...      12    --critical-demand-percentage=5                      CRITICAL: CPU average demand is 8.36 % | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;;0:5;; 'cpu.capacity.demand.hertz'=4201000Hz;;;;50280000
        ...      13    --warning-demand-frequency=5                        WARNING: demand frequency is 4201 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;;;; 'cpu.capacity.demand.hertz'=4201000Hz;0:5;;;50280000
        ...      14    --critical-demand-frequency=5                       CRITICAL: demand frequency is 4201 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.demand.percentage'=8.3552108194113;;;; 'cpu.capacity.demand.hertz'=4201000Hz;;0:5;;50280000
        ...      15    --warning-contention-percentage=5:                  WARNING: CPU average contention is 0.00 % | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;5:;;0;100 'cpu.capacity.contention.hertz'=550Hz;;;;50280000
        ...      16    --critical-contention-percentage=5:                 CRITICAL: CPU average contention is 0.00 % | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;;5:;0;100 'cpu.capacity.contention.hertz'=550Hz;;;;50280000
        ...      17    --warning-contention-frequency=5:                   WARNING: contention frequency is 0.55 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;;;0;100 'cpu.capacity.contention.hertz'=550Hz;5:;;;50280000
        ...      18    --critical-contention-frequency=5:                  CRITICAL: contention frequency is 0.55 kHz | 'cpu.capacity.usage.percentage'=9.16%;;;0;100 'cpu.capacity.usage.hertz'=4603440Hz;;;;50280000 'cpu.capacity.contention.percentage'=0.00%;;;0;100 'cpu.capacity.contention.hertz'=550Hz;;5:;;50280000
