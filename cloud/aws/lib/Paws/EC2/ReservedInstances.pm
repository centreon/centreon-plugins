package Paws::EC2::ReservedInstances {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has CurrencyCode => (is => 'ro', isa => 'Str', xmlname => 'currencyCode', traits => ['Unwrapped']);
  has Duration => (is => 'ro', isa => 'Int', xmlname => 'duration', traits => ['Unwrapped']);
  has End => (is => 'ro', isa => 'Str', xmlname => 'end', traits => ['Unwrapped']);
  has FixedPrice => (is => 'ro', isa => 'Num', xmlname => 'fixedPrice', traits => ['Unwrapped']);
  has InstanceCount => (is => 'ro', isa => 'Int', xmlname => 'instanceCount', traits => ['Unwrapped']);
  has InstanceTenancy => (is => 'ro', isa => 'Str', xmlname => 'instanceTenancy', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has OfferingType => (is => 'ro', isa => 'Str', xmlname => 'offeringType', traits => ['Unwrapped']);
  has ProductDescription => (is => 'ro', isa => 'Str', xmlname => 'productDescription', traits => ['Unwrapped']);
  has RecurringCharges => (is => 'ro', isa => 'ArrayRef[Paws::EC2::RecurringCharge]', xmlname => 'recurringCharges', traits => ['Unwrapped']);
  has ReservedInstancesId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesId', traits => ['Unwrapped']);
  has Start => (is => 'ro', isa => 'Str', xmlname => 'start', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has UsagePrice => (is => 'ro', isa => 'Num', xmlname => 'usagePrice', traits => ['Unwrapped']);
}
1;
