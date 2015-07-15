package Paws::MachineLearning::Evaluation {
  use Moose;
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CreatedByIamUser => (is => 'ro', isa => 'Str');
  has EvaluationDataSourceId => (is => 'ro', isa => 'Str');
  has EvaluationId => (is => 'ro', isa => 'Str');
  has InputDataLocationS3 => (is => 'ro', isa => 'Str');
  has LastUpdatedAt => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has PerformanceMetrics => (is => 'ro', isa => 'Paws::MachineLearning::PerformanceMetrics');
  has Status => (is => 'ro', isa => 'Str');
}
1;
