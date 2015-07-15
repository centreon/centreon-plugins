package Paws::IAM::UserDetail {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has AttachedManagedPolicies => (is => 'ro', isa => 'ArrayRef[Paws::IAM::AttachedPolicy]');
  has CreateDate => (is => 'ro', isa => 'Str');
  has GroupList => (is => 'ro', isa => 'ArrayRef[Str]');
  has Path => (is => 'ro', isa => 'Str');
  has UserId => (is => 'ro', isa => 'Str');
  has UserName => (is => 'ro', isa => 'Str');
  has UserPolicyList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyDetail]');
}
1;
