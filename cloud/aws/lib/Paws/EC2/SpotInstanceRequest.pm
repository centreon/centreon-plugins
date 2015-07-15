package Paws::EC2::SpotInstanceRequest {
  use Moose;
  has AvailabilityZoneGroup => (is => 'ro', isa => 'Str', xmlname => 'availabilityZoneGroup', traits => ['Unwrapped']);
  has CreateTime => (is => 'ro', isa => 'Str', xmlname => 'createTime', traits => ['Unwrapped']);
  has Fault => (is => 'ro', isa => 'Paws::EC2::SpotInstanceStateFault', xmlname => 'fault', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has LaunchGroup => (is => 'ro', isa => 'Str', xmlname => 'launchGroup', traits => ['Unwrapped']);
  has LaunchSpecification => (is => 'ro', isa => 'Paws::EC2::LaunchSpecification', xmlname => 'launchSpecification', traits => ['Unwrapped']);
  has LaunchedAvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'launchedAvailabilityZone', traits => ['Unwrapped']);
  has ProductDescription => (is => 'ro', isa => 'Str', xmlname => 'productDescription', traits => ['Unwrapped']);
  has SpotInstanceRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotInstanceRequestId', traits => ['Unwrapped']);
  has SpotPrice => (is => 'ro', isa => 'Str', xmlname => 'spotPrice', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Paws::EC2::SpotInstanceStatus', xmlname => 'status', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has Type => (is => 'ro', isa => 'Str', xmlname => 'type', traits => ['Unwrapped']);
  has ValidFrom => (is => 'ro', isa => 'Str', xmlname => 'validFrom', traits => ['Unwrapped']);
  has ValidUntil => (is => 'ro', isa => 'Str', xmlname => 'validUntil', traits => ['Unwrapped']);
}
1;
