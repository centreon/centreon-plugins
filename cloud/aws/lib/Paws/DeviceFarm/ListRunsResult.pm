
package Paws::DeviceFarm::ListRunsResult {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has runs => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Run]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListRunsResult

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.









=head2 runs => ArrayRef[Paws::DeviceFarm::Run]

  

Information about the runs.











=cut

1;