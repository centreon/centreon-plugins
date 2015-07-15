
package Paws::EFS::MountTargetDescription {
  use Moose;
  has FileSystemId => (is => 'ro', isa => 'Str', required => 1);
  has IpAddress => (is => 'ro', isa => 'Str');
  has LifeCycleState => (is => 'ro', isa => 'Str', required => 1);
  has MountTargetId => (is => 'ro', isa => 'Str', required => 1);
  has NetworkInterfaceId => (is => 'ro', isa => 'Str');
  has OwnerId => (is => 'ro', isa => 'Str');
  has SubnetId => (is => 'ro', isa => 'Str', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::MountTargetDescription

=head1 ATTRIBUTES

=head2 B<REQUIRED> FileSystemId => Str

  

The ID of the file system for which the mount target is intended.









=head2 IpAddress => Str

  

The address at which the file system may be mounted via the mount
target.









=head2 B<REQUIRED> LifeCycleState => Str

  

The lifecycle state the mount target is in.









=head2 B<REQUIRED> MountTargetId => Str

  

The system-assigned mount target ID.









=head2 NetworkInterfaceId => Str

  

The ID of the network interface that Amazon EFS created when it created
the mount target.









=head2 OwnerId => Str

  

The AWS account ID that owns the resource.









=head2 B<REQUIRED> SubnetId => Str

  

The ID of the subnet that the mount target is in.











=cut

