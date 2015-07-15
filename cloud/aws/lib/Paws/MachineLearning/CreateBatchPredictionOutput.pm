
package Paws::MachineLearning::CreateBatchPredictionOutput {
  use Moose;
  has BatchPredictionId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateBatchPredictionOutput

=head1 ATTRIBUTES

=head2 BatchPredictionId => Str

  

A user-supplied ID that uniquely identifies the C<BatchPrediction>.
This value is identical to the value of the C<BatchPredictionId> in the
request.











=cut

1;