
package Paws::RedShift::TaggedResourceListMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has TaggedResources => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::TaggedResource]', xmlname => 'TaggedResource', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::TaggedResourceListMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.









=head2 TaggedResources => ArrayRef[Paws::RedShift::TaggedResource]

  

A list of tags with their associated resources.











=cut

