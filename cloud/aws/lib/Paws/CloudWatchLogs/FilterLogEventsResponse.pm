
package Paws::CloudWatchLogs::FilterLogEventsResponse {
  use Moose;
  has events => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::FilteredLogEvent]');
  has nextToken => (is => 'ro', isa => 'Str');
  has searchedLogStreams => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::SearchedLogStream]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::FilterLogEventsResponse

=head1 ATTRIBUTES

=head2 events => ArrayRef[Paws::CloudWatchLogs::FilteredLogEvent]

  

A list of C<FilteredLogEvent> objects representing the matched events
from the request.









=head2 nextToken => Str

  

A pagination token obtained from a C<FilterLogEvents> response to
continue paginating the FilterLogEvents results.









=head2 searchedLogStreams => ArrayRef[Paws::CloudWatchLogs::SearchedLogStream]

  

A list of C<SearchedLogStream> objects indicating which log streams
have been searched in this request and whether each has been searched
completely or still has more to be paginated.











=cut

1;