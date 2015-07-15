package Paws::EC2::NetworkInterfaceAttachment {
  use Moose;
  has AttachTime => (is => 'ro', isa => 'Str', xmlname => 'attachTime', traits => ['Unwrapped']);
  has AttachmentId => (is => 'ro', isa => 'Str', xmlname => 'attachmentId', traits => ['Unwrapped']);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
  has DeviceIndex => (is => 'ro', isa => 'Int', xmlname => 'deviceIndex', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has InstanceOwnerId => (is => 'ro', isa => 'Str', xmlname => 'instanceOwnerId', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
}
1;
