
package Paws::MachineLearning::DescribeEvaluationsOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Results => (is => 'ro', isa => 'ArrayRef[Paws::MachineLearning::Evaluation]');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DescribeEvaluationsOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The ID of the next page in the paginated results that indicates at
least one more page follows.









=head2 Results => ArrayRef[Paws::MachineLearning::Evaluation]

  

A list of Evaluation that meet the search criteria.











=cut

1;