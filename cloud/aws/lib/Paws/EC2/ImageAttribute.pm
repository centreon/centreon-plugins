
package Paws::EC2::ImageAttribute {
  use Moose;
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BlockDeviceMapping]', xmlname => 'blockDeviceMapping', traits => ['Unwrapped',]);
  has Description => (is => 'ro', isa => 'Paws::EC2::AttributeValue', xmlname => 'description', traits => ['Unwrapped',]);
  has ImageId => (is => 'ro', isa => 'Str', xmlname => 'imageId', traits => ['Unwrapped',]);
  has KernelId => (is => 'ro', isa => 'Paws::EC2::AttributeValue', xmlname => 'kernel', traits => ['Unwrapped',]);
  has LaunchPermissions => (is => 'ro', isa => 'ArrayRef[Paws::EC2::LaunchPermission]', xmlname => 'launchPermission', traits => ['Unwrapped',]);
  has ProductCodes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ProductCode]', xmlname => 'productCodes', traits => ['Unwrapped',]);
  has RamdiskId => (is => 'ro', isa => 'Paws::EC2::AttributeValue', xmlname => 'ramdisk', traits => ['Unwrapped',]);
  has SriovNetSupport => (is => 'ro', isa => 'Paws::EC2::AttributeValue', xmlname => 'sriovNetSupport', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ImageAttribute

=head1 ATTRIBUTES

=head2 BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping]

  

One or more block device mapping entries.









=head2 Description => Paws::EC2::AttributeValue

  

A description for the AMI.









=head2 ImageId => Str

  

The ID of the AMI.









=head2 KernelId => Paws::EC2::AttributeValue

  

The kernel ID.









=head2 LaunchPermissions => ArrayRef[Paws::EC2::LaunchPermission]

  

One or more launch permissions.









=head2 ProductCodes => ArrayRef[Paws::EC2::ProductCode]

  

One or more product codes.









=head2 RamdiskId => Paws::EC2::AttributeValue

  

The RAM disk ID.









=head2 SriovNetSupport => Paws::EC2::AttributeValue

  


=cut

