package Paws::EC2::IamInstanceProfile {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', xmlname => 'arn', traits => ['Unwrapped']);
  has Id => (is => 'ro', isa => 'Str', xmlname => 'id', traits => ['Unwrapped']);
}
1;
