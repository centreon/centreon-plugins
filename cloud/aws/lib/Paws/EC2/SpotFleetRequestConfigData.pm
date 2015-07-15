package Paws::EC2::SpotFleetRequestConfigData {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', xmlname => 'clientToken', traits => ['Unwrapped']);
  has IamFleetRole => (is => 'ro', isa => 'Str', xmlname => 'iamFleetRole', traits => ['Unwrapped'], required => 1);
  has LaunchSpecifications => (is => 'ro', isa => 'ArrayRef[Paws::EC2::LaunchSpecification]', xmlname => 'launchSpecifications', traits => ['Unwrapped'], required => 1);
  has SpotPrice => (is => 'ro', isa => 'Str', xmlname => 'spotPrice', traits => ['Unwrapped'], required => 1);
  has TargetCapacity => (is => 'ro', isa => 'Int', xmlname => 'targetCapacity', traits => ['Unwrapped'], required => 1);
  has TerminateInstancesWithExpiration => (is => 'ro', isa => 'Bool', xmlname => 'terminateInstancesWithExpiration', traits => ['Unwrapped']);
  has ValidFrom => (is => 'ro', isa => 'Str', xmlname => 'validFrom', traits => ['Unwrapped']);
  has ValidUntil => (is => 'ro', isa => 'Str', xmlname => 'validUntil', traits => ['Unwrapped']);
}
1;
