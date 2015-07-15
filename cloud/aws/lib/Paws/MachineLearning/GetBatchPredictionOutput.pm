
package Paws::MachineLearning::GetBatchPredictionOutput {
  use Moose;
  has BatchPredictionDataSourceId => (is => 'ro', isa => 'Str');
  has BatchPredictionId => (is => 'ro', isa => 'Str');
  has CreatedAt => (is => 'ro', isa => 'Str');
  has CreatedByIamUser => (is => 'ro', isa => 'Str');
  has InputDataLocationS3 => (is => 'ro', isa => 'Str');
  has LastUpdatedAt => (is => 'ro', isa => 'Str');
  has LogUri => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has OutputUri => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::GetBatchPredictionOutput

=head1 ATTRIBUTES

=head2 BatchPredictionDataSourceId => Str

  

The ID of the C<DataSource> that was used to create the
C<BatchPrediction>.









=head2 BatchPredictionId => Str

  

An ID assigned to the C<BatchPrediction> at creation. This value should
be identical to the value of the C<BatchPredictionID> in the request.









=head2 CreatedAt => Str

  

The time when the C<BatchPrediction> was created. The time is expressed
in epoch time.









=head2 CreatedByIamUser => Str

  

The AWS user account that invoked the C<BatchPrediction>. The account
type can be either an AWS root account or an AWS Identity and Access
Management (IAM) user account.









=head2 InputDataLocationS3 => Str

  

The location of the data file or directory in Amazon Simple Storage
Service (Amazon S3).









=head2 LastUpdatedAt => Str

  

The time of the most recent edit to C<BatchPrediction>. The time is
expressed in epoch time.









=head2 LogUri => Str

  

A link to the file that contains logs of the CreateBatchPrediction
operation.









=head2 Message => Str

  

A description of the most recent details about processing the batch
prediction request.









=head2 MLModelId => Str

  

The ID of the C<MLModel> that generated predictions for the
C<BatchPrediction> request.









=head2 Name => Str

  

A user-supplied name or description of the C<BatchPrediction>.









=head2 OutputUri => Str

  

The location of an Amazon S3 bucket or directory to receive the
operation results.









=head2 Status => Str

  

The status of the C<BatchPrediction>, which can be one of the following
values:

=over

=item * C<PENDING> - Amazon Machine Learning (Amazon ML) submitted a
request to generate batch predictions.

=item * C<INPROGRESS> - The batch predictions are in progress.

=item * C<FAILED> - The request to perform a batch prediction did not
run to completion. It is not usable.

=item * C<COMPLETED> - The batch prediction process completed
successfully.

=item * C<DELETED> - The C<BatchPrediction> is marked as deleted. It is
not usable.

=back











=cut

1;