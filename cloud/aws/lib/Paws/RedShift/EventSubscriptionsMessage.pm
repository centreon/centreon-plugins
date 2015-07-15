
package Paws::RedShift::EventSubscriptionsMessage {
  use Moose;
  has EventSubscriptionsList => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::EventSubscription]', xmlname => 'EventSubscription', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::EventSubscriptionsMessage

=head1 ATTRIBUTES

=head2 EventSubscriptionsList => ArrayRef[Paws::RedShift::EventSubscription]

  

A list of event subscriptions.









=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.











=cut

