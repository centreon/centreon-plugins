package Paws::MachineLearning::RDSDataSpec {
  use Moose;
  has DataRearrangement => (is => 'ro', isa => 'Str');
  has DataSchema => (is => 'ro', isa => 'Str');
  has DataSchemaUri => (is => 'ro', isa => 'Str');
  has DatabaseCredentials => (is => 'ro', isa => 'Paws::MachineLearning::RDSDatabaseCredentials', required => 1);
  has DatabaseInformation => (is => 'ro', isa => 'Paws::MachineLearning::RDSDatabase', required => 1);
  has ResourceRole => (is => 'ro', isa => 'Str', required => 1);
  has S3StagingLocation => (is => 'ro', isa => 'Str', required => 1);
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has SelectSqlQuery => (is => 'ro', isa => 'Str', required => 1);
  has ServiceRole => (is => 'ro', isa => 'Str', required => 1);
  has SubnetId => (is => 'ro', isa => 'Str', required => 1);
}
1;
