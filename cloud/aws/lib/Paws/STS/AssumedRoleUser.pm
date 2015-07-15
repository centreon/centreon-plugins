package Paws::STS::AssumedRoleUser {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', required => 1);
  has AssumedRoleId => (is => 'ro', isa => 'Str', required => 1);
}
1;
