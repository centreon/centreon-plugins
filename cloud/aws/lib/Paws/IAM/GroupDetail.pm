package Paws::IAM::GroupDetail {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has AttachedManagedPolicies => (is => 'ro', isa => 'ArrayRef[Paws::IAM::AttachedPolicy]');
  has CreateDate => (is => 'ro', isa => 'Str');
  has GroupId => (is => 'ro', isa => 'Str');
  has GroupName => (is => 'ro', isa => 'Str');
  has GroupPolicyList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyDetail]');
  has Path => (is => 'ro', isa => 'Str');
}
1;
