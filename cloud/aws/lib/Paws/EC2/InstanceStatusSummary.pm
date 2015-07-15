package Paws::EC2::InstanceStatusSummary {
  use Moose;
  has Details => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceStatusDetails]', xmlname => 'details', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
}
1;
