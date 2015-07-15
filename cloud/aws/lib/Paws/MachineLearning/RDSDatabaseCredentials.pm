package Paws::MachineLearning::RDSDatabaseCredentials {
  use Moose;
  has Password => (is => 'ro', isa => 'Str', required => 1);
  has Username => (is => 'ro', isa => 'Str', required => 1);
}
1;
