package Paws::EC2::ImportInstanceTaskDetails {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has Platform => (is => 'ro', isa => 'Str', xmlname => 'platform', traits => ['Unwrapped']);
  has Volumes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ImportInstanceVolumeDetailItem]', xmlname => 'volumes', traits => ['Unwrapped'], required => 1);
}
1;
