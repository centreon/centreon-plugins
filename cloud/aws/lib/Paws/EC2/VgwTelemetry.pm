package Paws::EC2::VgwTelemetry {
  use Moose;
  has AcceptedRouteCount => (is => 'ro', isa => 'Int', xmlname => 'acceptedRouteCount', traits => ['Unwrapped']);
  has LastStatusChange => (is => 'ro', isa => 'Str', xmlname => 'lastStatusChange', traits => ['Unwrapped']);
  has OutsideIpAddress => (is => 'ro', isa => 'Str', xmlname => 'outsideIpAddress', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
}
1;
