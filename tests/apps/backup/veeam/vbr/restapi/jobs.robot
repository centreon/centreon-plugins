*** Settings ***
Documentation     apps::backup::veeam::vbr::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}veeam-vbr.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::backup::veeam::vbr::restapi::plugin
...                --mode=jobs
...                --http-peer-addr=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --api-username=username
...                --api-password=password


*** Test Cases ***
Jobs ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    ${EMPTY}
    ...    CRITICAL: job 'Agent backup job' [type: LinuxAgentBackup] status: Stopped, last result: Failed WARNING: job 'Backup copy job' [type: BackupCopy] status: Stopped, last result: Warning | 'jobs.detected.count'=5;;;0; 'jobs.success.count'=1;;;0;5 'jobs.warning.count'=1;;;0;5 'jobs.failed.count'=2;;;0;5
    ...    2
    ...    vbr.example.com
    ...    --critical-job-status='\\\%{last_result} =~ /failed/i'
    ...    CRITICAL: job 'Agent backup job' [type: LinuxAgentBackup] status: Stopped, last result: Failed - job 'Old backup job' [type: VSphereBackup] status: Disabled, last result: Failed WARNING: job 'Backup copy job' [type: BackupCopy] status: Stopped, last result: Warning | 'jobs.detected.count'=5;;;0; 'jobs.success.count'=1;;;0;5 'jobs.warning.count'=1;;;0;5 'jobs.failed.count'=2;;;0;5
    ...    3
    ...    vbr.example.com
    ...    --exclude-status=Disabled
    ...    CRITICAL: job 'Agent backup job' [type: LinuxAgentBackup] status: Stopped, last result: Failed WARNING: job 'Backup copy job' [type: BackupCopy] status: Stopped, last result: Warning | 'jobs.detected.count'=4;;;0; 'jobs.success.count'=1;;;0;4 'jobs.warning.count'=1;;;0;4 'jobs.failed.count'=1;;;0;4
    ...    4
    ...    vbr.example.com
    ...    --include-type=BackupCopy
    ...    WARNING: job 'Backup copy job' [type: BackupCopy] status: Stopped, last result: Warning | 'jobs.detected.count'=1;;;0; 'jobs.success.count'=0;;;0;1 'jobs.warning.count'=1;;;0;1 'jobs.failed.count'=0;;;0;1
    ...    5
    ...    vbr.example.com
    ...    --include-name='^Linux' --exclude-name=copy
    ...    OK: Number of jobs detected: 1, success: 1, warning: 0, failed: 0 - job 'Linux backup job' [type: VSphereBackup] status: Stopped, last result: Success | 'jobs.detected.count'=1;;;0; 'jobs.success.count'=1;;;0;1 'jobs.warning.count'=0;;;0;1 'jobs.failed.count'=0;;;0;1
    ...    6
    ...    vbr.example.com
    ...    --include-status=Running --warning-job-status='\\\%{status} =~ /running/i'
    ...    WARNING: job 'PostgreSQL backup' [type: VSphereBackup] status: Running, last result: None | 'jobs.detected.count'=1;;;0; 'jobs.success.count'=0;;;0;1 'jobs.warning.count'=0;;;0;1 'jobs.failed.count'=0;;;0;1
    ...    7
    ...    vbr.example.com
    ...    --critical-job-status='' --warning-job-status='\\\%{status} eq "Disabled"'
    ...    WARNING: job 'Old backup job' [type: VSphereBackup] status: Disabled, last result: Failed | 'jobs.detected.count'=5;;;0; 'jobs.success.count'=1;;;0;5 'jobs.warning.count'=1;;;0;5 'jobs.failed.count'=2;;;0;5
    ...    8
    ...    vbr.example.com
    ...    --critical-job-status='' --warning-job-status='' --critical-jobs-failed=0
    ...    CRITICAL: Number of jobs failed: 2 | 'jobs.detected.count'=5;;;0; 'jobs.success.count'=1;;;0;5 'jobs.warning.count'=1;;;0;5 'jobs.failed.count'=2;;0:0;0;5
    ...    9
    ...    paginated.example.com
    ...    ${EMPTY}
    ...    WARNING: job 'Backup copy job' [type: BackupCopy] status: Stopped, last result: Warning | 'jobs.detected.count'=3;;;0; 'jobs.success.count'=1;;;0;3 'jobs.warning.count'=1;;;0;3 'jobs.failed.count'=0;;;0;3
    ...    10
    ...    no-jobs.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: Number of jobs detected: 0 | 'jobs.detected.count'=0;;;0; 'jobs.success.count'=0;;;0;0 'jobs.warning.count'=0;;;0;0 'jobs.failed.count'=0;;;0;0

Jobs discovery ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>name</element> <element>type</element> <element>workload</element> <element>status</element> </data>
    ...    2
    ...    vbr.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label id="11111111-0000-0000-0000-000000000004" name="Agent backup job" status="Stopped" type="LinuxAgentBackup" workload="Server"/> <label id="11111111-0000-0000-0000-000000000003" name="Backup copy job" status="Stopped" type="BackupCopy" workload="Vm"/> <label id="11111111-0000-0000-0000-000000000001" name="Linux backup job" status="Stopped" type="VSphereBackup" workload="Vm"/> <label id="11111111-0000-0000-0000-000000000005" name="Old backup job" status="Disabled" type="VSphereBackup" workload="Vm"/> <label id="11111111-0000-0000-0000-000000000002" name="PostgreSQL backup" status="Running" type="VSphereBackup" workload="Application"/> </data>
    ...    3
    ...    vbr.example.com
    ...    --disco-show --exclude-status=Disabled
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label id="11111111-0000-0000-0000-000000000004" name="Agent backup job" status="Stopped" type="LinuxAgentBackup" workload="Server"/> <label id="11111111-0000-0000-0000-000000000003" name="Backup copy job" status="Stopped" type="BackupCopy" workload="Vm"/> <label id="11111111-0000-0000-0000-000000000001" name="Linux backup job" status="Stopped" type="VSphereBackup" workload="Vm"/> <label id="11111111-0000-0000-0000-000000000002" name="PostgreSQL backup" status="Running" type="VSphereBackup" workload="Application"/> </data>
