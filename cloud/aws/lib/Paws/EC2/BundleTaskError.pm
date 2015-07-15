package Paws::EC2::BundleTaskError {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped']);
  has Message => (is => 'ro', isa => 'Str', xmlname => 'message', traits => ['Unwrapped']);
}
1;
