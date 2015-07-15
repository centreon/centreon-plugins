
package Paws::EC2::ImportVolume {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'availabilityZone' , required => 1);
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'description' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Image => (is => 'ro', isa => 'Paws::EC2::DiskImageDetail', traits => ['NameInRequest'], request_name => 'image' , required => 1);
  has Volume => (is => 'ro', isa => 'Paws::EC2::VolumeDetail', traits => ['NameInRequest'], request_name => 'volume' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ImportVolume');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::ImportVolumeResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ImportVolume - Arguments for method ImportVolume on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ImportVolume on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ImportVolume.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ImportVolume.

As an example:

  $service_obj->ImportVolume(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AvailabilityZone => Str

  

The Availability Zone for the resulting EBS volume.










=head2 Description => Str

  

A description of the volume.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> Image => Paws::EC2::DiskImageDetail

  

The disk image.










=head2 B<REQUIRED> Volume => Paws::EC2::VolumeDetail

  

The volume size.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ImportVolume in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

