package Paws::RDS::DBSubnetGroup {
  use Moose;
  has DBSubnetGroupDescription => (is => 'ro', isa => 'Str');
  has DBSubnetGroupName => (is => 'ro', isa => 'Str');
  has SubnetGroupStatus => (is => 'ro', isa => 'Str');
  has Subnets => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Subnet]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
