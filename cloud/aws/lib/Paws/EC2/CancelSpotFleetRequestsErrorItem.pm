package Paws::EC2::CancelSpotFleetRequestsErrorItem {
  use Moose;
  has Error => (is => 'ro', isa => 'Paws::EC2::CancelSpotFleetRequestsError', xmlname => 'error', traits => ['Unwrapped'], required => 1);
  has SpotFleetRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestId', traits => ['Unwrapped'], required => 1);
}
1;
