
package Paws::CognitoSync::ListDatasetsResponse {
  use Moose;
  has Count => (is => 'ro', isa => 'Int');
  has Datasets => (is => 'ro', isa => 'ArrayRef[Paws::CognitoSync::Dataset]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::ListDatasetsResponse

=head1 ATTRIBUTES

=head2 Count => Int

  

Number of datasets returned.









=head2 Datasets => ArrayRef[Paws::CognitoSync::Dataset]

  

A set of datasets.









=head2 NextToken => Str

  

A pagination token for obtaining the next page of results.











=cut

