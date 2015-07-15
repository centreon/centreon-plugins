
package Paws::MachineLearning::DescribeDataSourcesOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Results => (is => 'ro', isa => 'ArrayRef[Paws::MachineLearning::DataSource]');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DescribeDataSourcesOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

An ID of the next page in the paginated results that indicates at least
one more page follows.









=head2 Results => ArrayRef[Paws::MachineLearning::DataSource]

  

A list of C<DataSource> that meet the search criteria.











=cut

1;