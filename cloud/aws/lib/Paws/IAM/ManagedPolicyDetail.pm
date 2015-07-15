package Paws::IAM::ManagedPolicyDetail {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has AttachmentCount => (is => 'ro', isa => 'Int');
  has CreateDate => (is => 'ro', isa => 'Str');
  has DefaultVersionId => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has IsAttachable => (is => 'ro', isa => 'Bool');
  has Path => (is => 'ro', isa => 'Str');
  has PolicyId => (is => 'ro', isa => 'Str');
  has PolicyName => (is => 'ro', isa => 'Str');
  has PolicyVersionList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyVersion]');
  has UpdateDate => (is => 'ro', isa => 'Str');
}
1;
