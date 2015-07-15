package Paws::RedShift::ClusterParameterStatus {
  use Moose;
  has ParameterApplyErrorDescription => (is => 'ro', isa => 'Str');
  has ParameterApplyStatus => (is => 'ro', isa => 'Str');
  has ParameterName => (is => 'ro', isa => 'Str');
}
1;
