package Paws::EC2::NewDhcpConfiguration {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', xmlname => 'key', traits => ['Unwrapped']);
  has Values => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Value', traits => ['Unwrapped']);
}
1;
