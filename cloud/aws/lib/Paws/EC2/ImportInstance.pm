
package Paws::EC2::ImportInstance {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'description' );
  has DiskImages => (is => 'ro', isa => 'ArrayRef[Paws::EC2::DiskImage]', traits => ['NameInRequest'], request_name => 'diskImage' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has LaunchSpecification => (is => 'ro', isa => 'Paws::EC2::ImportInstanceLaunchSpecification', traits => ['NameInRequest'], request_name => 'launchSpecification' );
  has Platform => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'platform' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ImportInstance');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::ImportInstanceResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ImportInstance - Arguments for method ImportInstance on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ImportInstance on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ImportInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ImportInstance.

As an example:

  $service_obj->ImportInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

A description for the instance being imported.










=head2 DiskImages => ArrayRef[Paws::EC2::DiskImage]

  

The disk image.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 LaunchSpecification => Paws::EC2::ImportInstanceLaunchSpecification

  

The launch specification.










=head2 B<REQUIRED> Platform => Str

  

The instance operating system.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ImportInstance in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

