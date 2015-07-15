package Paws::EMR::InstanceGroup {
  use Moose;
  has BidPrice => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has InstanceGroupType => (is => 'ro', isa => 'Str');
  has InstanceType => (is => 'ro', isa => 'Str');
  has Market => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has RequestedInstanceCount => (is => 'ro', isa => 'Int');
  has RunningInstanceCount => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Paws::EMR::InstanceGroupStatus');
}
1;
