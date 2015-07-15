package Paws::RDS::VpcSecurityGroupMembership {
  use Moose;
  has Status => (is => 'ro', isa => 'Str');
  has VpcSecurityGroupId => (is => 'ro', isa => 'Str');
}
1;
