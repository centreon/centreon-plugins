
package Paws::StorageGateway::DescribeTapeRecoveryPointsOutput {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has TapeRecoveryPointInfos => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::TapeRecoveryPointInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeTapeRecoveryPointsOutput

=head1 ATTRIBUTES

=head2 GatewayARN => Str

  
=head2 Marker => Str

  

An opaque string that indicates the position at which the virtual tape
recovery points that were listed for description ended.

Use this marker in your next request to list the next set of virtual
tape recovery points in the list. If there are no more recovery points
to describe, this field does not appear in the response.









=head2 TapeRecoveryPointInfos => ArrayRef[Paws::StorageGateway::TapeRecoveryPointInfo]

  

An array of TapeRecoveryPointInfos that are available for the specified
gateway.











=cut

1;