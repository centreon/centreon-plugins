
package Paws::EC2::ReportInstanceStatus {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'description' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has EndTime => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'endTime' );
  has Instances => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'instanceId' , required => 1);
  has ReasonCodes => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'reasonCode' , required => 1);
  has StartTime => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'startTime' );
  has Status => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'status' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ReportInstanceStatus');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ReportInstanceStatus - Arguments for method ReportInstanceStatus on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ReportInstanceStatus on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ReportInstanceStatus.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ReportInstanceStatus.

As an example:

  $service_obj->ReportInstanceStatus(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

Descriptive text about the health state of your instance.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 EndTime => Str

  

The time at which the reported instance health state ended.










=head2 B<REQUIRED> Instances => ArrayRef[Str]

  

One or more instances.










=head2 B<REQUIRED> ReasonCodes => ArrayRef[Str]

  

One or more reason codes that describes the health state of your
instance.

=over

=item *

C<instance-stuck-in-state>: My instance is stuck in a state.

=item *

C<unresponsive>: My instance is unresponsive.

=item *

C<not-accepting-credentials>: My instance is not accepting my
credentials.

=item *

C<password-not-available>: A password is not available for my instance.

=item *

C<performance-network>: My instance is experiencing performance
problems which I believe are network related.

=item *

C<performance-instance-store>: My instance is experiencing performance
problems which I believe are related to the instance stores.

=item *

C<performance-ebs-volume>: My instance is experiencing performance
problems which I believe are related to an EBS volume.

=item *

C<performance-other>: My instance is experiencing performance problems.

=item *

C<other>: [explain using the description parameter]

=back










=head2 StartTime => Str

  

The time at which the reported instance health state began.










=head2 B<REQUIRED> Status => Str

  

The status of all instances listed.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ReportInstanceStatus in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

