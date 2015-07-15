package Paws::EC2::ReservedInstancesModification {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', xmlname => 'clientToken', traits => ['Unwrapped']);
  has CreateDate => (is => 'ro', isa => 'Str', xmlname => 'createDate', traits => ['Unwrapped']);
  has EffectiveDate => (is => 'ro', isa => 'Str', xmlname => 'effectiveDate', traits => ['Unwrapped']);
  has ModificationResults => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ReservedInstancesModificationResult]', xmlname => 'modificationResultSet', traits => ['Unwrapped']);
  has ReservedInstancesIds => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ReservedInstancesId]', xmlname => 'reservedInstancesSet', traits => ['Unwrapped']);
  has ReservedInstancesModificationId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesModificationId', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
  has UpdateDate => (is => 'ro', isa => 'Str', xmlname => 'updateDate', traits => ['Unwrapped']);
}
1;
