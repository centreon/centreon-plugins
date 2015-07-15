package Paws::IAM::AttachedPolicy {
  use Moose;
  has PolicyArn => (is => 'ro', isa => 'Str');
  has PolicyName => (is => 'ro', isa => 'Str');
}
1;
