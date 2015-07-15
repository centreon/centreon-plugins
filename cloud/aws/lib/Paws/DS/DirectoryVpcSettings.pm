package Paws::DS::DirectoryVpcSettings {
  use Moose;
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has VpcId => (is => 'ro', isa => 'Str', required => 1);
}
1;
