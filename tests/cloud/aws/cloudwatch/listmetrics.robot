*** Settings ***
Documentation       AWS CloudWatch list-metrics mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudwatch::plugin
...         --custommode=awscli --region=eu-west
...         --aws-secret-key=secret --aws-access-key=key
...         --command=${CURDIR}${/}listmetrics_bin${/}mock_aws


*** Test Cases ***
AWS CloudWatch list-metrics ${tc}
    [Tags]    cloud    aws    cloudwatch    listmetrics
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-metrics
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                          expected_result    --
        ...      1     ${EMPTY}                                              List metrics: [Namespace = AWS/EC2][Dimensions = Name=InstanceId,Value=i-0123456789abcdef0][Metric = CPUUtilization][Dimension Metric = CPUUtilization InstanceId:i-0123456789abcdef0] [Namespace = AWS/EC2][Dimensions = Name=InstanceId,Value=i-0123456789abcdef0][Metric = NetworkIn][Dimension Metric = NetworkIn InstanceId:i-0123456789abcdef0] [Namespace = AWS/EBS][Dimensions = Name=VolumeId,Value=vol-049df61146c4d7901][Metric = VolumeReadBytes][Dimension Metric = VolumeReadBytes VolumeId:vol-049df61146c4d7901]
        ...      2     --namespace AWS/EC2                                   List metrics: [Namespace = AWS/EC2][Dimensions = Name=InstanceId,Value=i-0123456789abcdef0][Metric = CPUUtilization][Dimension Metric = CPUUtilization InstanceId:i-0123456789abcdef0] [Namespace = AWS/EC2][Dimensions = Name=InstanceId,Value=i-0123456789abcdef0][Metric = NetworkIn][Dimension Metric = NetworkIn InstanceId:i-0123456789abcdef0]
        ...      3     --namespace AWS/EC2 --metric CPUUtilization           List metrics: [Namespace = AWS/EC2][Dimensions = Name=InstanceId,Value=i-0123456789abcdef0][Metric = CPUUtilization][Dimension Metric = CPUUtilization InstanceId:i-0123456789abcdef0]
        ...      4     --namespace AWS/EBS --metric VolumeReadBytes          List metrics: [Namespace = AWS/EBS][Dimensions = Name=VolumeId,Value=vol-049df61146c4d7901][Metric = VolumeReadBytes][Dimension Metric = VolumeReadBytes VolumeId:vol-049df61146c4d7901]
        ...      5     --disco-format                                        <?xml version="1.0" encoding="utf-8"?> <data> <element>namespace</element> <element>metric</element> <element>dimensions</element> <element>dimension_metric</element> </data>
        ...      6     --disco-show                                          <?xml version="1.0" encoding="utf-8"?> <data> <label dimension_metric="CPUUtilization InstanceId:i-0123456789abcdef0" dimensions="Name=InstanceId,Value=i-0123456789abcdef0" metric="CPUUtilization" namespace="AWS/EC2"/> <label dimension_metric="NetworkIn InstanceId:i-0123456789abcdef0" dimensions="Name=InstanceId,Value=i-0123456789abcdef0" metric="NetworkIn" namespace="AWS/EC2"/> <label dimension_metric="VolumeReadBytes VolumeId:vol-049df61146c4d7901" dimensions="Name=VolumeId,Value=vol-049df61146c4d7901" metric="VolumeReadBytes" namespace="AWS/EBS"/> </data>                          
