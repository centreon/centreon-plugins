
package Paws::DeviceFarm::ListArtifactsResult {
  use Moose;
  has artifacts => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Artifact]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListArtifactsResult

=head1 ATTRIBUTES

=head2 artifacts => ArrayRef[Paws::DeviceFarm::Artifact]

  

Information about the artifacts.









=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.











=cut

1;