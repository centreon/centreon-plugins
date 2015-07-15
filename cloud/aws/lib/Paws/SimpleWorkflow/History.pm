
package Paws::SimpleWorkflow::History {
  use Moose;
  has events => (is => 'ro', isa => 'ArrayRef[Paws::SimpleWorkflow::HistoryEvent]', required => 1);
  has nextPageToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::History

=head1 ATTRIBUTES

=head2 B<REQUIRED> events => ArrayRef[Paws::SimpleWorkflow::HistoryEvent]

  

The list of history events.









=head2 nextPageToken => Str

  

If a C<NextPageToken> was returned by a previous call, there are more
results available. To retrieve the next page of results, make the call
again using the returned token in C<nextPageToken>. Keep all other
arguments unchanged.

The configured C<maximumPageSize> determines how many results can be
returned in a single call.











=cut

1;