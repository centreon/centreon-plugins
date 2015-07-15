
package Paws::CloudWatchLogs::GetLogEventsResponse {
  use Moose;
  has events => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::OutputLogEvent]');
  has nextBackwardToken => (is => 'ro', isa => 'Str');
  has nextForwardToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::GetLogEventsResponse

=head1 ATTRIBUTES

=head2 events => ArrayRef[Paws::CloudWatchLogs::OutputLogEvent]

  
=head2 nextBackwardToken => Str

  
=head2 nextForwardToken => Str

  


=cut

1;