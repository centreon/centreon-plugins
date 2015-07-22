
package Paws::DeviceFarm::ListSuitesResult {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has suites => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Suite]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListSuitesResult

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.









=head2 suites => ArrayRef[Paws::DeviceFarm::Suite]

  

Information about the suites.











=cut

1;