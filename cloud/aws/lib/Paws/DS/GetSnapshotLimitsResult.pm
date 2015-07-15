
package Paws::DS::GetSnapshotLimitsResult {
  use Moose;
  has SnapshotLimits => (is => 'ro', isa => 'Paws::DS::SnapshotLimits');

}

### main pod documentation begin ###

=head1 NAME

Paws::DS::GetSnapshotLimitsResult

=head1 ATTRIBUTES

=head2 SnapshotLimits => Paws::DS::SnapshotLimits

  

A SnapshotLimits object that contains the manual snapshot limits for
the specified directory.











=cut

1;