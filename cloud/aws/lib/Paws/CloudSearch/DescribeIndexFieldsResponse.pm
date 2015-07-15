
package Paws::CloudSearch::DescribeIndexFieldsResponse {
  use Moose;
  has IndexFields => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearch::IndexFieldStatus]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeIndexFieldsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> IndexFields => ArrayRef[Paws::CloudSearch::IndexFieldStatus]

  

The index fields configured for the domain.











=cut

