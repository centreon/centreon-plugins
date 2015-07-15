package Paws::MachineLearning::RedshiftMetadata {
  use Moose;
  has DatabaseUserName => (is => 'ro', isa => 'Str');
  has RedshiftDatabase => (is => 'ro', isa => 'Paws::MachineLearning::RedshiftDatabase');
  has SelectSqlQuery => (is => 'ro', isa => 'Str');
}
1;
