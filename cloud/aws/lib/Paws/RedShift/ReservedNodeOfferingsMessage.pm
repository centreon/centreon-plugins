
package Paws::RedShift::ReservedNodeOfferingsMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has ReservedNodeOfferings => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::ReservedNodeOffering]', xmlname => 'ReservedNodeOffering', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ReservedNodeOfferingsMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.









=head2 ReservedNodeOfferings => ArrayRef[Paws::RedShift::ReservedNodeOffering]

  

A list of reserved node offerings.











=cut

