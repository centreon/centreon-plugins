package Paws::RDS::DBSecurityGroupMembership {
  use Moose;
  has DBSecurityGroupName => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
