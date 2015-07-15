
package Paws::DataPipeline::QueryObjectsOutput {
  use Moose;
  has hasMoreResults => (is => 'ro', isa => 'Bool');
  has ids => (is => 'ro', isa => 'ArrayRef[Str]');
  has marker => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::QueryObjectsOutput

=head1 ATTRIBUTES

=head2 hasMoreResults => Bool

  

Indicates whether there are more results that can be obtained by a
subsequent call.









=head2 ids => ArrayRef[Str]

  

The identifiers that match the query selectors.









=head2 marker => Str

  

The starting point for the next page of results. To view the next page
of results, call C<QueryObjects> again with this marker value. If the
value is null, there are no more results.











=cut

1;