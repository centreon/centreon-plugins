package Paws::RedShift::ClusterSecurityGroupMembership {
  use Moose;
  has ClusterSecurityGroupName => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
