
package Paws::CloudWatchLogs::DescribeLogGroupsResponse {
  use Moose;
  has logGroups => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::LogGroup]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeLogGroupsResponse

=head1 ATTRIBUTES

=head2 logGroups => ArrayRef[Paws::CloudWatchLogs::LogGroup]

  
=head2 nextToken => Str

  


=cut

1;