*** Settings ***
Documentation       AWS Security Hub CSPM findings mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::aws::securityhub::plugin
...         --custommode=awscli --region=eu-west-1
...         --aws-secret-key=secret --aws-access-key=key


*** Test Cases ***
AWS Security Hub findings ${tc}
    [Tags]    cloud    aws    securityhub
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=findings
    ...    --command=${CURDIR}${/}findings_bin${/}mock_aws
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Findings critical: 2, high: 1, medium: 1, low: 1, informational: 1 - All resources are ok | 'findings.critical.total.count'=2;;;0; 'findings.high.total.count'=1;;;0; 'findings.medium.total.count'=1;;;0; 'findings.low.total.count'=1;;;0; 'findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.critical.total.count'=2;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.high.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.medium.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.low.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.informational.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0001#findings.total.count'=2;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.critical.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.high.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.medium.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.low.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.total.count'=3;;;0; 'arn:aws:s3:::my-bucket#findings.critical.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.high.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.medium.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.low.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.informational.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.total.count'=2;;;0;
    ...    2
    ...    --include-resource-type='^AwsS3Bucket$' --critical-findings-critical=0
    ...    CRITICAL: Findings critical: 1 | 'findings.critical.total.count'=1;;0:0;0; 'findings.high.total.count'=1;;;0; 'findings.medium.total.count'=0;;;0; 'findings.low.total.count'=0;;;0; 'findings.informational.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.critical.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.high.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.medium.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.low.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.informational.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.total.count'=2;;;0;
    ...    3
    ...    --include-resource-id='i-0002' --warning-resource-findings-medium=0
    ...    WARNING: resource 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002' type 'AwsEc2Instance' medium: 1 | 'findings.critical.total.count'=0;;;0; 'findings.high.total.count'=0;;;0; 'findings.medium.total.count'=1;;;0; 'findings.low.total.count'=1;;;0; 'findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.critical.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.high.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.medium.total.count'=1;0:0;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.low.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.total.count'=3;;;0;
    ...    4
    ...    --exclude-resource-type='AwsEc2Instance'
    ...    OK: Findings critical: 1, high: 1, medium: 0, low: 0, informational: 0 - resource 'arn:aws:s3:::my-bucket' type 'AwsS3Bucket' critical: 1, high: 1, medium: 0, low: 0, informational: 0, total: 2 | 'findings.critical.total.count'=1;;;0; 'findings.high.total.count'=1;;;0; 'findings.medium.total.count'=0;;;0; 'findings.low.total.count'=0;;;0; 'findings.informational.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.critical.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.high.total.count'=1;;;0; 'arn:aws:s3:::my-bucket#findings.medium.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.low.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.informational.total.count'=0;;;0; 'arn:aws:s3:::my-bucket#findings.total.count'=2;;;0;
    ...    5
    ...    --include-resource-id='i-0002' --critical-resource-findings-total=2
    ...    CRITICAL: resource 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002' type 'AwsEc2Instance' total: 3 | 'findings.critical.total.count'=0;;;0; 'findings.high.total.count'=0;;;0; 'findings.medium.total.count'=1;;;0; 'findings.low.total.count'=1;;;0; 'findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.critical.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.high.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.medium.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.low.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.total.count'=3;;0:2;0;
    ...    6
    ...    --include-resource-id='i-0002' --warning-findings-low=0
    ...    WARNING: Findings low: 1 | 'findings.critical.total.count'=0;;;0; 'findings.high.total.count'=0;;;0; 'findings.medium.total.count'=1;;;0; 'findings.low.total.count'=1;0:0;;0; 'findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.critical.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.high.total.count'=0;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.medium.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.low.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.informational.total.count'=1;;;0; 'arn:aws:ec2:eu-west-1:123456789012:instance/i-0002#findings.total.count'=3;;;0;
    ...    7
    ...    --filters='[1]'
    ...    UNKNOWN: Cannot decode --filters option: it must be a JSON object.
