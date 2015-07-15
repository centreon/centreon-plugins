
package Paws::Config::DescribeDeliveryChannelStatusResponse {
  use Moose;
  has DeliveryChannelsStatus => (is => 'ro', isa => 'ArrayRef[Paws::Config::DeliveryChannelStatus]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeDeliveryChannelStatusResponse

=head1 ATTRIBUTES

=head2 DeliveryChannelsStatus => ArrayRef[Paws::Config::DeliveryChannelStatus]

  

A list that contains the status of a specified delivery channel.











=cut

1;