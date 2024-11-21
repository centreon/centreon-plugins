*** Settings ***
Documentation       Hardware UPS standard SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                              ${CENTREON_PLUGINS} --plugin=hardware::ups::standard::rfc1628::snmp::plugin

*** Test Cases ***
Hardware UPS Standard SNMP input lines ${tc}
    [Tags]    hardware    ups    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=input-lines
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${snmpcommunity}
    ...    --warning-power=${warningpower}
    ...    --critical-current=${criticalcurrent}
    ...    --warning-voltage=${warningvoltage}
    ...    --warning-frequence=${warningfrequence}
    ...    --exclude-id=${excludeid}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  snmpcommunity                                         warningpower    criticalcurrent     warningvoltage    warningfrequence    excludeid    expected_result    --
            ...       1   hardware/ups/standard/snmp/ups-standard               ${EMPTY}        ${EMPTY}            ${EMPTY}          ${EMPTY}            ${EMPTY}     OK: All input lines are ok | '1#line.input.frequence.hertz'=49.9Hz;;;; '1#line.input.voltage.volt'=233V;;;; '1#line.input.current.ampere'=0A;;;; '1#line.input.power.watt'=0W;;;; '2#line.input.frequence.hertz'=49.9Hz;;;; '2#line.input.voltage.volt'=234V;;;; '2#line.input.current.ampere'=0A;;;; '2#line.input.power.watt'=0W;;;; '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
            ...       2   hardware/ups/standard/snmp/ups-standard-null-val      '215:'          '@0:214'            '@0:214'          '@0:214'            ${EMPTY}     CRITICAL: Input Line '1' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W - Input Line '2' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W - Input Line '3' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W | '1#line.input.frequence.hertz'=0Hz;@0:214;;; '1#line.input.voltage.volt'=0V;@0:214;;; '1#line.input.current.ampere'=0A;;@0:214;; '1#line.input.power.watt'=0W;215:;;; '2#line.input.frequence.hertz'=0Hz;@0:214;;; '2#line.input.voltage.volt'=0V;@0:214;;; '2#line.input.current.ampere'=0A;;@0:214;; '2#line.input.power.watt'=0W;215:;;; '3#line.input.frequence.hertz'=0Hz;@0:214;;; '3#line.input.voltage.volt'=0V;@0:214;;; '3#line.input.current.ampere'=0A;;@0:214;; '3#line.input.power.watt'=0W;215:;;;
            ...       3   hardware/ups/standard/snmp/ups-standard               ${EMPTY}        ${EMPTY}            ${EMPTY}          ${EMPTY}            '1,2'        OK: Input Line '3' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
            ...       4   hardware/ups/standard/snmp/ups-standard               ${EMPTY}        ${EMPTY}            ${EMPTY}          ${EMPTY}            '1, 2'       OK: Input Line '3' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
            ...       5   hardware/ups/standard/snmp/ups-standard               ${EMPTY}        ${EMPTY}            ${EMPTY}          ${EMPTY}            '1 ,3'       OK: Input Line '2' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '2#line.input.frequence.hertz'=49.9Hz;;;; '2#line.input.voltage.volt'=234V;;;; '2#line.input.current.ampere'=0A;;;; '2#line.input.power.watt'=0W;;;;