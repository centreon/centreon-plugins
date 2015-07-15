package Paws::EC2::IamInstanceProfileSpecification {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', xmlname => 'arn', traits => ['Unwrapped']);
  has Name => (is => 'ro', isa => 'Str', xmlname => 'name', traits => ['Unwrapped']);
}
1;
