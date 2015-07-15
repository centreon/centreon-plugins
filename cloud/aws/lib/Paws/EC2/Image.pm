package Paws::EC2::Image {
  use Moose;
  has Architecture => (is => 'ro', isa => 'Str', xmlname => 'architecture', traits => ['Unwrapped']);
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BlockDeviceMapping]', xmlname => 'blockDeviceMapping', traits => ['Unwrapped']);
  has CreationDate => (is => 'ro', isa => 'Str', xmlname => 'creationDate', traits => ['Unwrapped']);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has Hypervisor => (is => 'ro', isa => 'Str', xmlname => 'hypervisor', traits => ['Unwrapped']);
  has ImageId => (is => 'ro', isa => 'Str', xmlname => 'imageId', traits => ['Unwrapped']);
  has ImageLocation => (is => 'ro', isa => 'Str', xmlname => 'imageLocation', traits => ['Unwrapped']);
  has ImageOwnerAlias => (is => 'ro', isa => 'Str', xmlname => 'imageOwnerAlias', traits => ['Unwrapped']);
  has ImageType => (is => 'ro', isa => 'Str', xmlname => 'imageType', traits => ['Unwrapped']);
  has KernelId => (is => 'ro', isa => 'Str', xmlname => 'kernelId', traits => ['Unwrapped']);
  has Name => (is => 'ro', isa => 'Str', xmlname => 'name', traits => ['Unwrapped']);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'imageOwnerId', traits => ['Unwrapped']);
  has Platform => (is => 'ro', isa => 'Str', xmlname => 'platform', traits => ['Unwrapped']);
  has ProductCodes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ProductCode]', xmlname => 'productCodes', traits => ['Unwrapped']);
  has Public => (is => 'ro', isa => 'Bool', xmlname => 'isPublic', traits => ['Unwrapped']);
  has RamdiskId => (is => 'ro', isa => 'Str', xmlname => 'ramdiskId', traits => ['Unwrapped']);
  has RootDeviceName => (is => 'ro', isa => 'Str', xmlname => 'rootDeviceName', traits => ['Unwrapped']);
  has RootDeviceType => (is => 'ro', isa => 'Str', xmlname => 'rootDeviceType', traits => ['Unwrapped']);
  has SriovNetSupport => (is => 'ro', isa => 'Str', xmlname => 'sriovNetSupport', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'imageState', traits => ['Unwrapped']);
  has StateReason => (is => 'ro', isa => 'Paws::EC2::StateReason', xmlname => 'stateReason', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VirtualizationType => (is => 'ro', isa => 'Str', xmlname => 'virtualizationType', traits => ['Unwrapped']);
}
1;
