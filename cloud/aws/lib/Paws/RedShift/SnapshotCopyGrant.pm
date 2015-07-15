package Paws::RedShift::SnapshotCopyGrant {
  use Moose;
  has KmsKeyId => (is => 'ro', isa => 'Str');
  has SnapshotCopyGrantName => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');
}
1;
