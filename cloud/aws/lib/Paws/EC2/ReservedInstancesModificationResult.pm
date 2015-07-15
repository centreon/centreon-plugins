package Paws::EC2::ReservedInstancesModificationResult {
  use Moose;
  has ReservedInstancesId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesId', traits => ['Unwrapped']);
  has TargetConfiguration => (is => 'ro', isa => 'Paws::EC2::ReservedInstancesConfiguration', xmlname => 'targetConfiguration', traits => ['Unwrapped']);
}
1;
