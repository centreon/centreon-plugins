
package Paws::EC2::DescribeSpotDatafeedSubscriptionResult {
  use Moose;
  has SpotDatafeedSubscription => (is => 'ro', isa => 'Paws::EC2::SpotDatafeedSubscription', xmlname => 'spotDatafeedSubscription', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSpotDatafeedSubscriptionResult

=head1 ATTRIBUTES

=head2 SpotDatafeedSubscription => Paws::EC2::SpotDatafeedSubscription

  

The Spot Instance data feed subscription.











=cut

