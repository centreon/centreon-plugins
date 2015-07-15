package Paws::EC2::NetworkAclAssociation {
  use Moose;
  has NetworkAclAssociationId => (is => 'ro', isa => 'Str', xmlname => 'networkAclAssociationId', traits => ['Unwrapped']);
  has NetworkAclId => (is => 'ro', isa => 'Str', xmlname => 'networkAclId', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
}
1;
