
package Paws::CloudTrail::LookupEventsResponse {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::CloudTrail::Event]');
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail::LookupEventsResponse

=head1 ATTRIBUTES

=head2 Events => ArrayRef[Paws::CloudTrail::Event]

  

A list of events returned based on the lookup attributes specified and
the CloudTrail event. The events list is sorted by time. The most
recent event is listed first.









=head2 NextToken => Str

  

The token to use to get the next page of results after a previous API
call. If the token does not appear, there are no more results to
return. The token must be passed in with the same parameters as the
previous call. For example, if the original call specified an
AttributeKey of 'Username' with a value of 'root', the call with
NextToken should include those same parameters.











=cut

1;