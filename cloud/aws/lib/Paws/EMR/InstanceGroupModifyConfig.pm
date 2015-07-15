package Paws::EMR::InstanceGroupModifyConfig {
  use Moose;
  has EC2InstanceIdsToTerminate => (is => 'ro', isa => 'ArrayRef[Str]');
  has InstanceCount => (is => 'ro', isa => 'Int');
  has InstanceGroupId => (is => 'ro', isa => 'Str', required => 1);
}
1;
