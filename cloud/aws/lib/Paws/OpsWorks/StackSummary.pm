package Paws::OpsWorks::StackSummary {
  use Moose;
  has AppsCount => (is => 'ro', isa => 'Int');
  has Arn => (is => 'ro', isa => 'Str');
  has InstancesCount => (is => 'ro', isa => 'Paws::OpsWorks::InstancesCount');
  has LayersCount => (is => 'ro', isa => 'Int');
  has Name => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');
}
1;
