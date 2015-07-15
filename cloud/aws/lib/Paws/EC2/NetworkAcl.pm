package Paws::EC2::NetworkAcl {
  use Moose;
  has Associations => (is => 'ro', isa => 'ArrayRef[Paws::EC2::NetworkAclAssociation]', xmlname => 'associationSet', traits => ['Unwrapped']);
  has Entries => (is => 'ro', isa => 'ArrayRef[Paws::EC2::NetworkAclEntry]', xmlname => 'entrySet', traits => ['Unwrapped']);
  has IsDefault => (is => 'ro', isa => 'Bool', xmlname => 'default', traits => ['Unwrapped']);
  has NetworkAclId => (is => 'ro', isa => 'Str', xmlname => 'networkAclId', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
