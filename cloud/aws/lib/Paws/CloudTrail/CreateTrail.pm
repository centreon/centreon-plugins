
package Paws::CloudTrail::CreateTrail {
  use Moose;
  has CloudWatchLogsLogGroupArn => (is => 'ro', isa => 'Str');
  has CloudWatchLogsRoleArn => (is => 'ro', isa => 'Str');
  has IncludeGlobalServiceEvents => (is => 'ro', isa => 'Bool');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has S3BucketName => (is => 'ro', isa => 'Str', required => 1);
  has S3KeyPrefix => (is => 'ro', isa => 'Str');
  has SnsTopicName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateTrail');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudTrail::CreateTrailResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail::CreateTrail - Arguments for method CreateTrail on Paws::CloudTrail

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateTrail on the 
AWS CloudTrail service. Use the attributes of this class
as arguments to method CreateTrail.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateTrail.

As an example:

  $service_obj->CreateTrail(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CloudWatchLogsLogGroupArn => Str

  

Specifies a log group name using an Amazon Resource Name (ARN), a
unique identifier that represents the log group to which CloudTrail
logs will be delivered. Not required unless you specify
CloudWatchLogsRoleArn.










=head2 CloudWatchLogsRoleArn => Str

  

Specifies the role for the CloudWatch Logs endpoint to assume to write
to a userE<acirc>E<128>E<153>s log group.










=head2 IncludeGlobalServiceEvents => Bool

  

Specifies whether the trail is publishing events from global services
such as IAM to the log files.










=head2 B<REQUIRED> Name => Str

  

Specifies the name of the trail.










=head2 B<REQUIRED> S3BucketName => Str

  

Specifies the name of the Amazon S3 bucket designated for publishing
log files.










=head2 S3KeyPrefix => Str

  

Specifies the Amazon S3 key prefix that precedes the name of the bucket
you have designated for log file delivery.










=head2 SnsTopicName => Str

  

Specifies the name of the Amazon SNS topic defined for notification of
log file delivery.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateTrail in L<Paws::CloudTrail>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

