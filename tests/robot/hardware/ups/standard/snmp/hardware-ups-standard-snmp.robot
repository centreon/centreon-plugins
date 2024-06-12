*** Settings ***
Documentation       Hardware UPS standard SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                              ${CENTREON_PLUGINS} --plugin=hardware::ups::standard::rfc1628::snmp::plugin

&{ups_standard_test_with_values}
...                                                 snmpcommunity=hardware/ups/standard/snmp/ups-standard
...                                                 warningpower=
...                                                 criticalcurrent=
...                                                 warningvoltage=
...                                                 warningfrequence=
...                                                 excludeid=
...                                                 result=OK: All input lines are ok | '1#line.input.frequence.hertz'=49.9Hz;;;; '1#line.input.voltage.volt'=233V;;;; '1#line.input.current.ampere'=0A;;;; '1#line.input.power.watt'=0W;;;; '2#line.input.frequence.hertz'=49.9Hz;;;; '2#line.input.voltage.volt'=234V;;;; '2#line.input.current.ampere'=0A;;;; '2#line.input.power.watt'=0W;;;; '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
&{ups_standard_test_critical_with_null_values}
...                                                 snmpcommunity=hardware/ups/standard/snmp/ups-standard-null-val
...                                                 warningpower='215:'
...                                                 criticalcurrent='@0:214'
...                                                 warningvoltage='@0:214'
...                                                 warningfrequence='@0:214'
...                                                 excludeid=
...                                                 result=CRITICAL: Input Line '1' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W - Input Line '2' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W - Input Line '3' Frequence : 0.00 Hz, Voltage : 0.00 V, Current : 0.00 A, Power : 0.00 W | '1#line.input.frequence.hertz'=0Hz;@0:214;;; '1#line.input.voltage.volt'=0V;@0:214;;; '1#line.input.current.ampere'=0A;;@0:214;; '1#line.input.power.watt'=0W;215:;;; '2#line.input.frequence.hertz'=0Hz;@0:214;;; '2#line.input.voltage.volt'=0V;@0:214;;; '2#line.input.current.ampere'=0A;;@0:214;; '2#line.input.power.watt'=0W;215:;;; '3#line.input.frequence.hertz'=0Hz;@0:214;;; '3#line.input.voltage.volt'=0V;@0:214;;; '3#line.input.current.ampere'=0A;;@0:214;; '3#line.input.power.watt'=0W;215:;;;
&{ups_standard_test_with_exclude_option_1}
...                                                 snmpcommunity=hardware/ups/standard/snmp/ups-standard
...                                                 warningpower=
...                                                 criticalcurrent=
...                                                 warningvoltage=
...                                                 warningfrequence=
...                                                 excludeid='1,2'
...                                                 result=OK: Input Line '3' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
&{ups_standard_test_with_exclude_option_2}
...                                                 snmpcommunity=hardware/ups/standard/snmp/ups-standard
...                                                 warningpower=
...                                                 criticalcurrent=
...                                                 warningvoltage=
...                                                 warningfrequence=
...                                                 excludeid='1, 2'
...                                                 result=OK: Input Line '3' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '3#line.input.frequence.hertz'=49.9Hz;;;; '3#line.input.voltage.volt'=234V;;;; '3#line.input.current.ampere'=0A;;;; '3#line.input.power.watt'=0W;;;;
&{ups_standard_test_with_exclude_option_3}
...                                                 snmpcommunity=hardware/ups/standard/snmp/ups-standard
...                                                 warningpower=
...                                                 criticalcurrent=
...                                                 warningvoltage=
...                                                 warningfrequence=
...                                                 excludeid='1 ,3'
...                                                 result=OK: Input Line '2' Frequence : 49.90 Hz, Voltage : 234.00 V, Current : 0.00 A, Power : 0.00 W | '2#line.input.frequence.hertz'=49.9Hz;;;; '2#line.input.voltage.volt'=234V;;;; '2#line.input.current.ampere'=0A;;;; '2#line.input.power.watt'=0W;;;;
@{ups_standard_tests}
...                                                 &{ups_standard_test_with_values}
...                                                 &{ups_standard_test_critical_with_null_values}
...                                                 &{ups_standard_test_with_exclude_option_1}
...                                                 &{ups_standard_test_with_exclude_option_2}
...                                                 &{ups_standard_test_with_exclude_option_3}


*** Test Cases ***
Hardware UPS Standard SNMP input lines
    [Documentation]    Hardware UPS standard SNMP input lines
    [Tags]    hardware    ups    snmp
    FOR    ${ups_standard_test}    IN    @{ups_standard_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=input-lines
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=${ups_standard_test.snmpcommunity}
        ${length}    Get Length    ${ups_standard_test.warningpower}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-power=${ups_standard_test.warningpower}
        END
        ${length}    Get Length    ${ups_standard_test.criticalcurrent}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-current=${ups_standard_test.criticalcurrent}
        END
        ${length}    Get Length    ${ups_standard_test.warningvoltage}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-voltage=${ups_standard_test.warningvoltage}
        END
        ${length}    Get Length    ${ups_standard_test.warningfrequence}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-frequence=${ups_standard_test.warningfrequence}
        END
        ${length}    Get Length    ${ups_standard_test.excludeid}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --exclude-id=${ups_standard_test.excludeid}
        END
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${ups_standard_test.result}
        ...    Wrong output result for compliance of ${ups_standard_test.result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
    END
