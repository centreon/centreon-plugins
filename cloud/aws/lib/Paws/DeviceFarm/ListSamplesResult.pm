
package Paws::DeviceFarm::ListSamplesResult {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has samples => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Sample]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListSamplesResult

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.









=head2 samples => ArrayRef[Paws::DeviceFarm::Sample]

  

Information about the samples.











=cut

1;