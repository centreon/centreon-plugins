package Paws::EC2::NetworkInterfaceAttachmentChanges {
  use Moose;
  has AttachmentId => (is => 'ro', isa => 'Str', xmlname => 'attachmentId', traits => ['Unwrapped']);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
}
1;
