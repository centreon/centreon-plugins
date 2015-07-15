
package Paws::Config::DescribeDeliveryChannelsResponse {
  use Moose;
  has DeliveryChannels => (is => 'ro', isa => 'ArrayRef[Paws::Config::DeliveryChannel]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeDeliveryChannelsResponse

=head1 ATTRIBUTES

=head2 DeliveryChannels => ArrayRef[Paws::Config::DeliveryChannel]

  

A list that contains the descriptions of the specified delivery
channel.











=cut

1;