package Paws::EMR::InstanceGroupDetail {
  use Moose;
  has BidPrice => (is => 'ro', isa => 'Str');
  has CreationDateTime => (is => 'ro', isa => 'Str', required => 1);
  has EndDateTime => (is => 'ro', isa => 'Str');
  has InstanceGroupId => (is => 'ro', isa => 'Str');
  has InstanceRequestCount => (is => 'ro', isa => 'Int', required => 1);
  has InstanceRole => (is => 'ro', isa => 'Str', required => 1);
  has InstanceRunningCount => (is => 'ro', isa => 'Int', required => 1);
  has InstanceType => (is => 'ro', isa => 'Str', required => 1);
  has LastStateChangeReason => (is => 'ro', isa => 'Str');
  has Market => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str');
  has ReadyDateTime => (is => 'ro', isa => 'Str');
  has StartDateTime => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str', required => 1);
}
1;
