package Paws::STS::FederatedUser {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', required => 1);
  has FederatedUserId => (is => 'ro', isa => 'Str', required => 1);
}
1;
