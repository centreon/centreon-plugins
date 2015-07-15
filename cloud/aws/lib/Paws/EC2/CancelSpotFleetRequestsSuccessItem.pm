package Paws::EC2::CancelSpotFleetRequestsSuccessItem {
  use Moose;
  has CurrentSpotFleetRequestState => (is => 'ro', isa => 'Str', xmlname => 'currentSpotFleetRequestState', traits => ['Unwrapped'], required => 1);
  has PreviousSpotFleetRequestState => (is => 'ro', isa => 'Str', xmlname => 'previousSpotFleetRequestState', traits => ['Unwrapped'], required => 1);
  has SpotFleetRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestId', traits => ['Unwrapped'], required => 1);
}
1;
