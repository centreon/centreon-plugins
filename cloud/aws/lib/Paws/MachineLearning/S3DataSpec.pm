package Paws::MachineLearning::S3DataSpec {
  use Moose;
  has DataLocationS3 => (is => 'ro', isa => 'Str', required => 1);
  has DataRearrangement => (is => 'ro', isa => 'Str');
  has DataSchema => (is => 'ro', isa => 'Str');
  has DataSchemaLocationS3 => (is => 'ro', isa => 'Str');
}
1;
