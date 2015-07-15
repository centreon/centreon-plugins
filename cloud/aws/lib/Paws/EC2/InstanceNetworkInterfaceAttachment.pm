package Paws::EC2::InstanceNetworkInterfaceAttachment {
  use Moose;
  has AttachTime => (is => 'ro', isa => 'Str', xmlname => 'attachTime', traits => ['Unwrapped']);
  has AttachmentId => (is => 'ro', isa => 'Str', xmlname => 'attachmentId', traits => ['Unwrapped']);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
  has DeviceIndex => (is => 'ro', isa => 'Int', xmlname => 'deviceIndex', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
}
1;
