package Paws::EMR::ClusterSummary {
  use Moose;
  has Id => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has NormalizedInstanceHours => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Paws::EMR::ClusterStatus');
}
1;
