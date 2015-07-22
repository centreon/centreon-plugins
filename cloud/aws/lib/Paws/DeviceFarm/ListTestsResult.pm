
package Paws::DeviceFarm::ListTestsResult {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has tests => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Test]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListTestsResult

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.









=head2 tests => ArrayRef[Paws::DeviceFarm::Test]

  

Information about the tests.











=cut

1;