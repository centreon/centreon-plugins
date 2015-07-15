
package Paws::MachineLearning::DeleteBatchPredictionOutput {
  use Moose;
  has BatchPredictionId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DeleteBatchPredictionOutput

=head1 ATTRIBUTES

=head2 BatchPredictionId => Str

  

A user-supplied ID that uniquely identifies the C<BatchPrediction>.
This value should be identical to the value of the C<BatchPredictionID>
in the request.











=cut

1;