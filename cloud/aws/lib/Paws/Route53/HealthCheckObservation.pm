package Paws::Route53::HealthCheckObservation {
  use Moose;
  has IPAddress => (is => 'ro', isa => 'Str');
  has StatusReport => (is => 'ro', isa => 'Paws::Route53::StatusReport');
}
1;
