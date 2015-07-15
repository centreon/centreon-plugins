
package Paws::EC2::DescribeSnapshotAttributeResult {
  use Moose;
  has CreateVolumePermissions => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CreateVolumePermission]', xmlname => 'createVolumePermission', traits => ['Unwrapped',]);
  has ProductCodes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ProductCode]', xmlname => 'productCodes', traits => ['Unwrapped',]);
  has SnapshotId => (is => 'ro', isa => 'Str', xmlname => 'snapshotId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSnapshotAttributeResult

=head1 ATTRIBUTES

=head2 CreateVolumePermissions => ArrayRef[Paws::EC2::CreateVolumePermission]

  

A list of permissions for creating volumes from the snapshot.









=head2 ProductCodes => ArrayRef[Paws::EC2::ProductCode]

  

A list of product codes.









=head2 SnapshotId => Str

  

The ID of the EBS snapshot.











=cut

