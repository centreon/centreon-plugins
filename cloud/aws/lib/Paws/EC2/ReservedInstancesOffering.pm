package Paws::EC2::ReservedInstancesOffering {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has CurrencyCode => (is => 'ro', isa => 'Str', xmlname => 'currencyCode', traits => ['Unwrapped']);
  has Duration => (is => 'ro', isa => 'Int', xmlname => 'duration', traits => ['Unwrapped']);
  has FixedPrice => (is => 'ro', isa => 'Num', xmlname => 'fixedPrice', traits => ['Unwrapped']);
  has InstanceTenancy => (is => 'ro', isa => 'Str', xmlname => 'instanceTenancy', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has Marketplace => (is => 'ro', isa => 'Bool', xmlname => 'marketplace', traits => ['Unwrapped']);
  has OfferingType => (is => 'ro', isa => 'Str', xmlname => 'offeringType', traits => ['Unwrapped']);
  has PricingDetails => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PricingDetail]', xmlname => 'pricingDetailsSet', traits => ['Unwrapped']);
  has ProductDescription => (is => 'ro', isa => 'Str', xmlname => 'productDescription', traits => ['Unwrapped']);
  has RecurringCharges => (is => 'ro', isa => 'ArrayRef[Paws::EC2::RecurringCharge]', xmlname => 'recurringCharges', traits => ['Unwrapped']);
  has ReservedInstancesOfferingId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesOfferingId', traits => ['Unwrapped']);
  has UsagePrice => (is => 'ro', isa => 'Num', xmlname => 'usagePrice', traits => ['Unwrapped']);
}
1;
