
package Paws::MachineLearning::UpdateBatchPredictionOutput {
  use Moose;
  has BatchPredictionId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::UpdateBatchPredictionOutput

=head1 ATTRIBUTES

=head2 BatchPredictionId => Str

  

The ID assigned to the C<BatchPrediction> during creation. This value
should be identical to the value of the C<BatchPredictionId> in the
request.











=cut

1;