package Paws::MachineLearning::RealtimeEndpointInfo {
  use Moose;
  has CreatedAt => (is => 'ro', isa => 'Str');
  has EndpointStatus => (is => 'ro', isa => 'Str');
  has EndpointUrl => (is => 'ro', isa => 'Str');
  has PeakRequestsPerSecond => (is => 'ro', isa => 'Int');
}
1;
