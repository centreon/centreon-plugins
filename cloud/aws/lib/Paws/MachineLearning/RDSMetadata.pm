package Paws::MachineLearning::RDSMetadata {
  use Moose;
  has DataPipelineId => (is => 'ro', isa => 'Str');
  has Database => (is => 'ro', isa => 'Paws::MachineLearning::RDSDatabase');
  has DatabaseUserName => (is => 'ro', isa => 'Str');
  has ResourceRole => (is => 'ro', isa => 'Str');
  has SelectSqlQuery => (is => 'ro', isa => 'Str');
  has ServiceRole => (is => 'ro', isa => 'Str');
}
1;
