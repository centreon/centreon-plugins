package Paws::IAM::RoleDetail {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has AssumeRolePolicyDocument => (is => 'ro', isa => 'Str', decode_as => 'URLJSON', method => 'Policy', traits => ['JSONAttribute']);
  has AttachedManagedPolicies => (is => 'ro', isa => 'ArrayRef[Paws::IAM::AttachedPolicy]');
  has CreateDate => (is => 'ro', isa => 'Str');
  has InstanceProfileList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::InstanceProfile]');
  has Path => (is => 'ro', isa => 'Str');
  has RoleId => (is => 'ro', isa => 'Str');
  has RoleName => (is => 'ro', isa => 'Str');
  has RolePolicyList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyDetail]');
}
1;
