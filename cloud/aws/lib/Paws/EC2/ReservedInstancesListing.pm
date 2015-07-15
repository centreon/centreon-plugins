package Paws::EC2::ReservedInstancesListing {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', xmlname => 'clientToken', traits => ['Unwrapped']);
  has CreateDate => (is => 'ro', isa => 'Str', xmlname => 'createDate', traits => ['Unwrapped']);
  has InstanceCounts => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceCount]', xmlname => 'instanceCounts', traits => ['Unwrapped']);
  has PriceSchedules => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PriceSchedule]', xmlname => 'priceSchedules', traits => ['Unwrapped']);
  has ReservedInstancesId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesId', traits => ['Unwrapped']);
  has ReservedInstancesListingId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesListingId', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has UpdateDate => (is => 'ro', isa => 'Str', xmlname => 'updateDate', traits => ['Unwrapped']);
}
1;
