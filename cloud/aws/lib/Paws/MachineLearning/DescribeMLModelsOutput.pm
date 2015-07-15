
package Paws::MachineLearning::DescribeMLModelsOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Results => (is => 'ro', isa => 'ArrayRef[Paws::MachineLearning::MLModel]');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DescribeMLModelsOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The ID of the next page in the paginated results that indicates at
least one more page follows.









=head2 Results => ArrayRef[Paws::MachineLearning::MLModel]

  

A list of MLModel that meet the search criteria.











=cut

1;