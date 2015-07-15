package Paws::RDS::DBSecurityGroup {
  use Moose;
  has DBSecurityGroupDescription => (is => 'ro', isa => 'Str');
  has DBSecurityGroupName => (is => 'ro', isa => 'Str');
  has EC2SecurityGroups => (is => 'ro', isa => 'ArrayRef[Paws::RDS::EC2SecurityGroup]');
  has IPRanges => (is => 'ro', isa => 'ArrayRef[Paws::RDS::IPRange]');
  has OwnerId => (is => 'ro', isa => 'Str');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
