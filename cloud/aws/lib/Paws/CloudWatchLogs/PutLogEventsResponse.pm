
package Paws::CloudWatchLogs::PutLogEventsResponse {
  use Moose;
  has nextSequenceToken => (is => 'ro', isa => 'Str');
  has rejectedLogEventsInfo => (is => 'ro', isa => 'Paws::CloudWatchLogs::RejectedLogEventsInfo');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::PutLogEventsResponse

=head1 ATTRIBUTES

=head2 nextSequenceToken => Str

  
=head2 rejectedLogEventsInfo => Paws::CloudWatchLogs::RejectedLogEventsInfo

  


=cut

1;