
package Paws::SES::GetSendStatisticsResponse {
  use Moose;
  has SendDataPoints => (is => 'ro', isa => 'ArrayRef[Paws::SES::SendDataPoint]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::GetSendStatisticsResponse

=head1 ATTRIBUTES

=head2 SendDataPoints => ArrayRef[Paws::SES::SendDataPoint]

  

A list of data points, each of which represents 15 minutes of activity.











=cut

