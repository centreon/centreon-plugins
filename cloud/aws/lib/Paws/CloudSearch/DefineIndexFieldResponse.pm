
package Paws::CloudSearch::DefineIndexFieldResponse {
  use Moose;
  has IndexField => (is => 'ro', isa => 'Paws::CloudSearch::IndexFieldStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DefineIndexFieldResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> IndexField => Paws::CloudSearch::IndexFieldStatus

  


=cut

