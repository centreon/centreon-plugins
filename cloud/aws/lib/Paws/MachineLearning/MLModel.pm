package Paws::MachineLearning::MLModel {
  use Moose;
  has Algorithm => (is => 'ro', isa => 'Str');
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CreatedByIamUser => (is => 'ro', isa => 'Str');
  has EndpointInfo => (is => 'ro', isa => 'Paws::MachineLearning::RealtimeEndpointInfo');
  has InputDataLocationS3 => (is => 'ro', isa => 'Str');
  has LastUpdatedAt => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str');
  has MLModelType => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has ScoreThreshold => (is => 'ro', isa => 'Num');
  has ScoreThresholdLastUpdatedAt => (is => 'ro', isa => 'Str');
  has SizeInBytes => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Str');
  has TrainingDataSourceId => (is => 'ro', isa => 'Str');
  has TrainingParameters => (is => 'ro', isa => 'Paws::MachineLearning::TrainingParameters');
}
1;
