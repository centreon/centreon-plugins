*** Settings ***
Documentation       apps::backup::veeam::vone::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vone.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::backup::veeam::vone::restapi::plugin
...         --mode=proxies
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --api-username=UsErNaMe
...         --api-password=P@s$W0Rd


*** Test Cases ***
Proxies ${tc}
    [Tags]    apps    backup    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All proxies are ok | 'proxies.detected.count'=2;;;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    2
    ...    --filter-uid=abvcd-6788-sdsdf
    ...    OK: proxy 'fake-02' [type: Vmware] state: ok | 'proxies.detected.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    3
    ...    --filter-name=fake-01
    ...    OK: proxy 'fake-01' [type: Vmware] state: ok | 'proxies.detected.count'=1;;;0; 'fake-01#proxy.state.count'=1;;;0;
    ...    4
    ...    --unknown-proxy-status='%\\\{state\\\} =~ /ok/'
    ...    UNKNOWN: proxy 'fake-01' [type: Vmware] state: ok - proxy 'fake-02' [type: Vmware] state: ok | 'proxies.detected.count'=2;;;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    5
    ...    --warning-proxy-status='%\\\{state\\\} =~ /ok/'
    ...    WARNING: proxy 'fake-01' [type: Vmware] state: ok - proxy 'fake-02' [type: Vmware] state: ok | 'proxies.detected.count'=2;;;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    6
    ...    --critical-proxy-status='%\\\{state\\\} =~ /ok/'
    ...    CRITICAL: proxy 'fake-01' [type: Vmware] state: ok - proxy 'fake-02' [type: Vmware] state: ok | 'proxies.detected.count'=2;;;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    7
    ...    --warning-proxies-detected=:1
    ...    WARNING: Number of proxies detected: 2 | 'proxies.detected.count'=2;0:1;;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    8
    ...    --critical-proxies-detected=:1
    ...    CRITICAL: Number of proxies detected: 2 | 'proxies.detected.count'=2;;0:1;0; 'fake-01#proxy.state.count'=1;;;0; 'fake-02#proxy.state.count'=1;;;0;
    ...    9
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>uid</element> <element>name</element> <element>type</element> <element>state</element> <element>enabled</element> </data>
    ...    10
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label enabled="1" name="fake-01" state="ok" type="Vmware" uid="12345-6789-18"/> <label enabled="1" name="fake-02" state="ok" type="Vmware" uid="abvcd-6788-sdsdf"/> </data>
