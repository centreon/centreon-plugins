*** Settings ***
Documentation       Check cpu table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
cpu-detailed ${tc}
    [Tags]    os    linux   cpu
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu-detailed
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --critical-guest                OK: CPU Usage: user : Buffer creation, nice : Buffer creation, system : Buffer creation, idle : Buffer creation, wait : Buffer creation, kernel : Buffer creation, interrupt : Buffer creation, softirq : Buffer creation, steal : Buffer creation, guest : Buffer creation, guestnice : Buffer creation
            ...      2     --warning-nice                  OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      3     --warning-system                OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      4     --warning-idle                  OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      5     --warning-wait                  OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      6     --warning-kernel                OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      7     --warning-interrupt             OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      8     --warning-softirq               OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      9     --warning-steal                 OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      10    --warning-guest                 OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      11    --warning-guestnice             OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      12    --critical-guestnice            OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      13    --critical-user=''              OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      14    --critical-nice                 OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      15    --critical-system               OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      16    --critical-idle                 OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      17    --critical-wait                 OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      18    --critical-kernel               OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      19    --critical-interrupt            OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved 
            ...      20    --critical-softirq              OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
            ...      21    --critical-steal                OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved