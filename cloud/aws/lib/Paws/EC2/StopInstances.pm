
package Paws::EC2::StopInstances {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Force => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'force' );
  has InstanceIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'InstanceId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'StopInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::StopInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::StopInstances - Arguments for method StopInstances on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method StopInstances on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method StopInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to StopInstances.

As an example:

  $service_obj->StopInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Force => Bool

  

Forces the instances to stop. The instances do not have an opportunity
to flush file system caches or file system metadata. If you use this
option, you must perform file system check and repair procedures. This
option is not recommended for Windows instances.

Default: C<false>










=head2 B<REQUIRED> InstanceIds => ArrayRef[Str]

  

One or more instance IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method StopInstances in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

