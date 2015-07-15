package Paws::OpsWorks::UserProfile {
  use Moose;
  has AllowSelfManagement => (is => 'ro', isa => 'Bool');
  has IamUserArn => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has SshPublicKey => (is => 'ro', isa => 'Str');
  has SshUsername => (is => 'ro', isa => 'Str');
}
1;
