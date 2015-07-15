
package Paws::CloudSearch::DeleteIndexFieldResponse {
  use Moose;
  has IndexField => (is => 'ro', isa => 'Paws::CloudSearch::IndexFieldStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DeleteIndexFieldResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> IndexField => Paws::CloudSearch::IndexFieldStatus

  

The status of the index field being deleted.











=cut

