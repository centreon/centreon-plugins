
package Paws::EC2::CreateFlowLogs {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str');
  has DeliverLogsPermissionArn => (is => 'ro', isa => 'Str', required => 1);
  has LogGroupName => (is => 'ro', isa => 'Str', required => 1);
  has ResourceIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ResourceId' , required => 1);
  has ResourceType => (is => 'ro', isa => 'Str', required => 1);
  has TrafficType => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateFlowLogs');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateFlowLogsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateFlowLogs - Arguments for method CreateFlowLogs on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateFlowLogs on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateFlowLogs.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateFlowLogs.

As an example:

  $service_obj->CreateFlowLogs(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request. For more information, see How to Ensure Idempotency.










=head2 B<REQUIRED> DeliverLogsPermissionArn => Str

  

The ARN for the IAM role that's used to post flow logs to a CloudWatch
Logs log group.










=head2 B<REQUIRED> LogGroupName => Str

  

The name of the CloudWatch log group.










=head2 B<REQUIRED> ResourceIds => ArrayRef[Str]

  

One or more subnet, network interface, or VPC IDs.










=head2 B<REQUIRED> ResourceType => Str

  

The type of resource on which to create the flow log.










=head2 B<REQUIRED> TrafficType => Str

  

The type of traffic to log.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateFlowLogs in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

