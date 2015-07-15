
package Paws::StorageGateway::DescribeTapesOutput {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has Tapes => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::Tape]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeTapesOutput

=head1 ATTRIBUTES

=head2 Marker => Str

  

An opaque string which can be used as part of a subsequent
DescribeTapes call to retrieve the next page of results.

If a response does not contain a marker, then there are no more results
to be retrieved.









=head2 Tapes => ArrayRef[Paws::StorageGateway::Tape]

  

An array of virtual tape descriptions.











=cut

1;