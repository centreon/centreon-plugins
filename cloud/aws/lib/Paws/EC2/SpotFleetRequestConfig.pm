package Paws::EC2::SpotFleetRequestConfig {
  use Moose;
  has SpotFleetRequestConfig => (is => 'ro', isa => 'Paws::EC2::SpotFleetRequestConfigData', xmlname => 'spotFleetRequestConfig', traits => ['Unwrapped'], required => 1);
  has SpotFleetRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestId', traits => ['Unwrapped'], required => 1);
  has SpotFleetRequestState => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestState', traits => ['Unwrapped'], required => 1);
}
1;
