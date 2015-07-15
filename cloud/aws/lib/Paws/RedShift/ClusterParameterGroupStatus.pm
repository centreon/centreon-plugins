package Paws::RedShift::ClusterParameterGroupStatus {
  use Moose;
  has ClusterParameterStatusList => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::ClusterParameterStatus]');
  has ParameterApplyStatus => (is => 'ro', isa => 'Str');
  has ParameterGroupName => (is => 'ro', isa => 'Str');
}
1;
