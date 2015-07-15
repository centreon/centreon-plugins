package Paws::EC2::CancelledSpotInstanceRequest {
  use Moose;
  has SpotInstanceRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotInstanceRequestId', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
}
1;
