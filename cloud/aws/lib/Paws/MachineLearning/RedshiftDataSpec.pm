package Paws::MachineLearning::RedshiftDataSpec {
  use Moose;
  has DataRearrangement => (is => 'ro', isa => 'Str');
  has DataSchema => (is => 'ro', isa => 'Str');
  has DataSchemaUri => (is => 'ro', isa => 'Str');
  has DatabaseCredentials => (is => 'ro', isa => 'Paws::MachineLearning::RedshiftDatabaseCredentials', required => 1);
  has DatabaseInformation => (is => 'ro', isa => 'Paws::MachineLearning::RedshiftDatabase', required => 1);
  has S3StagingLocation => (is => 'ro', isa => 'Str', required => 1);
  has SelectSqlQuery => (is => 'ro', isa => 'Str', required => 1);
}
1;
