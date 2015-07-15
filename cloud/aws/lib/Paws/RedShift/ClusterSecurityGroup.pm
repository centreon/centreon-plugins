package Paws::RedShift::ClusterSecurityGroup {
  use Moose;
  has ClusterSecurityGroupName => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has EC2SecurityGroups => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::EC2SecurityGroup]');
  has IPRanges => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::IPRange]');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');
}
1;
