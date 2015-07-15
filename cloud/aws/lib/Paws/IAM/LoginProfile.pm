package Paws::IAM::LoginProfile {
  use Moose;
  has CreateDate => (is => 'ro', isa => 'Str', required => 1);
  has PasswordResetRequired => (is => 'ro', isa => 'Bool');
  has UserName => (is => 'ro', isa => 'Str', required => 1);
}
1;
