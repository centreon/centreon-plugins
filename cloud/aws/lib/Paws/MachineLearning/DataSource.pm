package Paws::MachineLearning::DataSource {
  use Moose;
  has ComputeStatistics => (is => 'ro', isa => 'Bool');
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CreatedByIamUser => (is => 'ro', isa => 'Str');
  has DataLocationS3 => (is => 'ro', isa => 'Str');
  has DataRearrangement => (is => 'ro', isa => 'Str');
  has DataSizeInBytes => (is => 'ro', isa => 'Int');
  has DataSourceId => (is => 'ro', isa => 'Str');
  has LastUpdatedAt => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has NumberOfFiles => (is => 'ro', isa => 'Int');
  has RDSMetadata => (is => 'ro', isa => 'Paws::MachineLearning::RDSMetadata');
  has RedshiftMetadata => (is => 'ro', isa => 'Paws::MachineLearning::RedshiftMetadata');
  has RoleARN => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
