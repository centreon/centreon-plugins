package Paws::IAM::InstanceProfile {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', required => 1);
  has CreateDate => (is => 'ro', isa => 'Str', required => 1);
  has InstanceProfileId => (is => 'ro', isa => 'Str', required => 1);
  has InstanceProfileName => (is => 'ro', isa => 'Str', required => 1);
  has Path => (is => 'ro', isa => 'Str', required => 1);
  has Roles => (is => 'ro', isa => 'ArrayRef[Paws::IAM::Role]', required => 1);
}
1;
