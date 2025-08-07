*** Settings ***
Documentation       Apache Jmeter scenario

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::jmeter::plugin

*** Test Cases ***
Scenario ${tc}
    [Documentation]    Scenario
    [Tags]    apps    jmeter    scenario

    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=scenario
    ...    --directory=${CURDIR}
    ...    --scenario=${scenario}
    ...    --command-path=${CURDIR}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:
    ...    tc    scenario    extraoptions         expected_result    --
    ...    1     test_2_2    ${EMPTY}             OK: Elapsed Time: 1.690s, Steps: 4/4, Availability: 100% | 'time'=1.690s;;;0; 'steps'=4;;;0;4 'availability'=100%;;;0;100
    ...    2     test_2_2    --warning-time=1     WARNING: Elapsed Time: 1.690s | 'time'=1.690s;0:1;;0; 'steps'=4;;;0;4 'availability'=100%;;;0;100
    ...    3     test_2_2    --critical-time=1    CRITICAL: Elapsed Time: 1.690s | 'time'=1.690s;;0:1;0; 'steps'=4;;;0;4 'availability'=100%;;;0;100
    ...    4     test_1_2    ${EMPTY}             CRITICAL: Steps: 1/2 - First failed: Sample Label 2 (404 Not Found) | 'time'=0.457s;;;0; 'steps'=1;;;0;2 'availability'=50%;;;0;100
    ...    5     test_0_2    ${EMPTY}             CRITICAL: Steps: 0/2 - First failed: Sample Label (404 Not Found) | 'time'=0.457s;;;0; 'steps'=0;;;0;2 'availability'=0%;;;0;100
    ...    6     test_2_2    --verbose            OK: Elapsed Time: 1.690s, Steps: 4/4, Availability: 100% | 'time'=1.690s;;;0; 'steps'=4;;;0;4 'availability'=100%;;;0;100\n* Sample: Sample Label\n- Success: true\n- Elapsed Time: 0.123s\n- Response Code: 200\n- Response Message: OK\n- Assertion: Response Assertion\n* Sample: Sample Label\n- Success: true\n- Elapsed Time: 0.234s\n- Response Code: 200\n- Response Message: OK\n- Assertion: Response Assertion\n* Sample: Sample Label 2\n- Success: true\n- Elapsed Time: 1.456s\n- Response Code: 200\n- Response Message: OK\n- Assertion: Response 2 Assertion\n* Sample: Sample Label 2\n- Success: true\n- Elapsed Time: 0.345s\n- Response Code: 200\n- Response Message: OK\n- Assertion: Response 2 Assertion
    ...    7     test_1_2    --verbose            CRITICAL: Steps: 1/2 - First failed: Sample Label 2 (404 Not Found) | 'time'=0.457s;;;0; 'steps'=1;;;0;2 'availability'=50%;;;0;100\n* Sample: Sample Label\n- Success: true\n- Elapsed Time: 0.123s\n- Response Code: 200\n- Response Message: OK\n- Assertion: Response Assertion\n* Sample: Sample Label 2\n- Success: false\n- Elapsed Time: 0.456s\n- Response Code: 404\n- Response Message: Not Found\n- Assertion: Response 2 Assertion\n+ Failure Message: Test failed
    ...    8     test_0_2    --verbose            CRITICAL: Steps: 0/2 - First failed: Sample Label (404 Not Found) | 'time'=0.457s;;;0; 'steps'=0;;;0;2 'availability'=0%;;;0;100\n* Sample: Sample Label\n- Success: false\n- Elapsed Time: 0.123s\n- Response Code: 404\n- Response Message: Not Found\n- Assertion: Response Assertion\n+ Failure Message: Test failed\n* Sample: Sample Label 2\n- Success: false\n- Elapsed Time: 0.456s\n- Response Code: 404\n- Response Message: Not Found\n- Assertion: Response 2 Assertion\n+ Failure Message: Test 2 failed
