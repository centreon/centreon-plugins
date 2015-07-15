
package Paws::RedShift::EventsMessage {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Event]', xmlname => 'Event', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::EventsMessage

=head1 ATTRIBUTES

=head2 Events => ArrayRef[Paws::RedShift::Event]

  

A list of Event instances.









=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.











=cut

