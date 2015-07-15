
package Paws::MachineLearning::GetEvaluationOutput {
  use Moose;
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CreatedByIamUser => (is => 'ro', isa => 'Str');
  has EvaluationDataSourceId => (is => 'ro', isa => 'Str');
  has EvaluationId => (is => 'ro', isa => 'Str');
  has InputDataLocationS3 => (is => 'ro', isa => 'Str');
  has LastUpdatedAt => (is => 'ro', isa => 'Str');
  has LogUri => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has PerformanceMetrics => (is => 'ro', isa => 'Paws::MachineLearning::PerformanceMetrics');
  has Status => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::GetEvaluationOutput

=head1 ATTRIBUTES

=head2 CreatedAt => Str

  

The time that the C<Evaluation> was created. The time is expressed in
epoch time.









=head2 CreatedByIamUser => Str

  

The AWS user account that invoked the evaluation. The account type can
be either an AWS root account or an AWS Identity and Access Management
(IAM) user account.









=head2 EvaluationDataSourceId => Str

  

The C<DataSource> used for this evaluation.









=head2 EvaluationId => Str

  

The evaluation ID which is same as the C<EvaluationId> in the request.









=head2 InputDataLocationS3 => Str

  

The location of the data file or directory in Amazon Simple Storage
Service (Amazon S3).









=head2 LastUpdatedAt => Str

  

The time of the most recent edit to the C<BatchPrediction>. The time is
expressed in epoch time.









=head2 LogUri => Str

  

A link to the file that contains logs of the CreateEvaluation
operation.









=head2 Message => Str

  

A description of the most recent details about evaluating the
C<MLModel>.









=head2 MLModelId => Str

  

The ID of the C<MLModel> that was the focus of the evaluation.









=head2 Name => Str

  

A user-supplied name or description of the C<Evaluation>.









=head2 PerformanceMetrics => Paws::MachineLearning::PerformanceMetrics

  

Measurements of how well the C<MLModel> performed using observations
referenced by the C<DataSource>. One of the following metric is
returned based on the type of the C<MLModel>:

=over

=item *

BinaryAUC: A binary C<MLModel> uses the Area Under the Curve (AUC)
technique to measure performance.

=item *

RegressionRMSE: A regression C<MLModel> uses the Root Mean Square Error
(RMSE) technique to measure performance. RMSE measures the difference
between predicted and actual values for a single variable.

=item *

MulticlassAvgFScore: A multiclass C<MLModel> uses the F1 score
technique to measure performance.

=back

For more information about performance metrics, please see the Amazon
Machine Learning Developer Guide.









=head2 Status => Str

  

The status of the evaluation. This element can have one of the
following values:

=over

=item * C<PENDING> - Amazon Machine Language (Amazon ML) submitted a
request to evaluate an C<MLModel>.

=item * C<INPROGRESS> - The evaluation is underway.

=item * C<FAILED> - The request to evaluate an C<MLModel> did not run
to completion. It is not usable.

=item * C<COMPLETED> - The evaluation process completed successfully.

=item * C<DELETED> - The C<Evaluation> is marked as deleted. It is not
usable.

=back











=cut

1;