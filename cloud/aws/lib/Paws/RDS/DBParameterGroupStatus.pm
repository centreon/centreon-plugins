package Paws::RDS::DBParameterGroupStatus {
  use Moose;
  has DBParameterGroupName => (is => 'ro', isa => 'Str');
  has ParameterApplyStatus => (is => 'ro', isa => 'Str');
}
1;
