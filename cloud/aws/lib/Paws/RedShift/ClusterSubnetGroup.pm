package Paws::RedShift::ClusterSubnetGroup {
  use Moose;
  has ClusterSubnetGroupName => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has SubnetGroupStatus => (is => 'ro', isa => 'Str');
  has Subnets => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Subnet]');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
