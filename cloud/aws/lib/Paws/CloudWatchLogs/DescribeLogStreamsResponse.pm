
package Paws::CloudWatchLogs::DescribeLogStreamsResponse {
  use Moose;
  has logStreams => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::LogStream]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeLogStreamsResponse

=head1 ATTRIBUTES

=head2 logStreams => ArrayRef[Paws::CloudWatchLogs::LogStream]

  
=head2 nextToken => Str

  


=cut

1;