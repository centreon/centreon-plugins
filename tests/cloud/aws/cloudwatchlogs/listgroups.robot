*** Settings ***
Documentation     AWS CloudWatch Logs list-groups mode

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}cloud-aws-cloudwatchlogs.json

${CMD}             ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudwatchlogs::plugin --mode=list-groups --region=eu-west-1 --aws-secret-key=secret --aws-access-key=key
${PAWS}            --custommode=paws --endpoint=http://localhost:3000/logs/describe
${AWSCLI}          --custommode=awscli --command-path=${CURDIR}${/}bin


*** Test Cases ***
AWS CloudWatch Logs list-groups ${tc}
    [Documentation]    List the log groups with both custom modes.
    [Tags]    cloud    aws    cloudwatchlogs    listgroups

    ${command}    Catenate
    ...    ${CMD}
    ...    ${custommode}
    ...    ${extraoptions}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    custommode
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${PAWS}
    ...    ${EMPTY}
    ...    List log groups: [group name = /aws/lambda/demo-function] [group name = /aws/rds/instance/demo-db/error] [group name = /ecs/demo-service]
    ...    2
    ...    ${AWSCLI}
    ...    ${EMPTY}
    ...    List log groups: [group name = /aws/lambda/demo-function] [group name = /aws/rds/instance/demo-db/error] [group name = /ecs/demo-service]
    ...    3
    ...    ${PAWS}
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>group_name</element> </data>
    ...    4
    ...    ${PAWS}
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label group_name="/aws/lambda/demo-function"/> <label group_name="/aws/rds/instance/demo-db/error"/> <label group_name="/ecs/demo-service"/> </data>
    ...    5
    ...    ${AWSCLI}
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label group_name="/aws/lambda/demo-function"/> <label group_name="/aws/rds/instance/demo-db/error"/> <label group_name="/ecs/demo-service"/> </data>
