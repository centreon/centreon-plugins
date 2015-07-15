package Paws::RDS::DBParameterGroup {
  use Moose;
  has DBParameterGroupFamily => (is => 'ro', isa => 'Str');
  has DBParameterGroupName => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
}
1;
