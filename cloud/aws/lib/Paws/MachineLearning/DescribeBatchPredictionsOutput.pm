
package Paws::MachineLearning::DescribeBatchPredictionsOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Results => (is => 'ro', isa => 'ArrayRef[Paws::MachineLearning::BatchPrediction]');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DescribeBatchPredictionsOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The ID of the next page in the paginated results that indicates at
least one more page follows.









=head2 Results => ArrayRef[Paws::MachineLearning::BatchPrediction]

  

A list of BatchPrediction objects that meet the search criteria.











=cut

1;