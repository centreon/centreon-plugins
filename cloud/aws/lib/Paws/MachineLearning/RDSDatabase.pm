package Paws::MachineLearning::RDSDatabase {
  use Moose;
  has DatabaseName => (is => 'ro', isa => 'Str', required => 1);
  has InstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
}
1;
