
package Paws::EC2::ImportSnapshotResult {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped',]);
  has ImportTaskId => (is => 'ro', isa => 'Str', xmlname => 'importTaskId', traits => ['Unwrapped',]);
  has SnapshotTaskDetail => (is => 'ro', isa => 'Paws::EC2::SnapshotTaskDetail', xmlname => 'snapshotTaskDetail', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ImportSnapshotResult

=head1 ATTRIBUTES

=head2 Description => Str

  

A description of the import snapshot task.









=head2 ImportTaskId => Str

  

The ID of the import snapshot task.









=head2 SnapshotTaskDetail => Paws::EC2::SnapshotTaskDetail

  

Information about the import snapshot task.











=cut

