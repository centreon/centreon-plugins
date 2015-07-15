package Paws::EC2::CancelSpotFleetRequestsError {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped'], required => 1);
  has Message => (is => 'ro', isa => 'Str', xmlname => 'message', traits => ['Unwrapped'], required => 1);
}
1;
