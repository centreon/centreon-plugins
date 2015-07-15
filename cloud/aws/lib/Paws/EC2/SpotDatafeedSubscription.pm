package Paws::EC2::SpotDatafeedSubscription {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', xmlname => 'bucket', traits => ['Unwrapped']);
  has Fault => (is => 'ro', isa => 'Paws::EC2::SpotInstanceStateFault', xmlname => 'fault', traits => ['Unwrapped']);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped']);
  has Prefix => (is => 'ro', isa => 'Str', xmlname => 'prefix', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
}
1;
