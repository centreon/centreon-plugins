package Paws::IAM::PolicyUser {
  use Moose;
  has UserName => (is => 'ro', isa => 'Str');
}
1;
