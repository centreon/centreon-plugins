package Paws::AutoScaling::EnabledMetric {
  use Moose;
  has Granularity => (is => 'ro', isa => 'Str');
  has Metric => (is => 'ro', isa => 'Str');
}
1;
