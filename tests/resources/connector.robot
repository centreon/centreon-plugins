*** Settings ***
Library    connector.py
Library    OperatingSystem
Library    String

*** Test Cases ***
START
    Remove File	  /tmp/connector.output
    Start Connector

SEND1
    Send To Connector    12    10    perl /home/code/connector.pl
    ${result}    Set Variable    ${0}
    FOR    ${i}    IN RANGE    10
        ${result}    Grep File    /tmp/connector.output    Hello from connector.pl
        ${result}    Get Line Count    ${result}
	IF    ${result} > 0
	    BREAK
	END
	Sleep    1s
    END
    Should Be True    ${result} > 0

STOP
    Stop Connector