package Paws::EC2::InstanceStatusEvent {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped']);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has NotAfter => (is => 'ro', isa => 'Str', xmlname => 'notAfter', traits => ['Unwrapped']);
  has NotBefore => (is => 'ro', isa => 'Str', xmlname => 'notBefore', traits => ['Unwrapped']);
}
1;
