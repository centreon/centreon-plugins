package Paws::EC2::BundleTask {
  use Moose;
  has BundleId => (is => 'ro', isa => 'Str', xmlname => 'bundleId', traits => ['Unwrapped']);
  has BundleTaskError => (is => 'ro', isa => 'Paws::EC2::BundleTaskError', xmlname => 'error', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has Progress => (is => 'ro', isa => 'Str', xmlname => 'progress', traits => ['Unwrapped']);
  has StartTime => (is => 'ro', isa => 'Str', xmlname => 'startTime', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Storage => (is => 'ro', isa => 'Paws::EC2::Storage', xmlname => 'storage', traits => ['Unwrapped']);
  has UpdateTime => (is => 'ro', isa => 'Str', xmlname => 'updateTime', traits => ['Unwrapped']);
}
1;
