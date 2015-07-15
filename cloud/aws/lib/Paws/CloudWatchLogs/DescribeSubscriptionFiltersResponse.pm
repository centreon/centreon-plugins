
package Paws::CloudWatchLogs::DescribeSubscriptionFiltersResponse {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has subscriptionFilters => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::SubscriptionFilter]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeSubscriptionFiltersResponse

=head1 ATTRIBUTES

=head2 nextToken => Str

  
=head2 subscriptionFilters => ArrayRef[Paws::CloudWatchLogs::SubscriptionFilter]

  


=cut

1;