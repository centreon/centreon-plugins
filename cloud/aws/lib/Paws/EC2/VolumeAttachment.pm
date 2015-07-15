
package Paws::EC2::VolumeAttachment {
  use Moose;
  has AttachTime => (is => 'ro', isa => 'Str', xmlname => 'attachTime', traits => ['Unwrapped',]);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped',]);
  has Device => (is => 'ro', isa => 'Str', xmlname => 'device', traits => ['Unwrapped',]);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped',]);
  has State => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::VolumeAttachment

=head1 ATTRIBUTES

=head2 AttachTime => Str

  

The time stamp when the attachment initiated.









=head2 DeleteOnTermination => Bool

  

Indicates whether the EBS volume is deleted on instance termination.









=head2 Device => Str

  

The device name.









=head2 InstanceId => Str

  

The ID of the instance.









=head2 State => Str

  

The attachment state of the volume.









=head2 VolumeId => Str

  

The ID of the volume.











=cut

