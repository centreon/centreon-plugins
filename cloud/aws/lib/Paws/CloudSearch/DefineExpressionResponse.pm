
package Paws::CloudSearch::DefineExpressionResponse {
  use Moose;
  has Expression => (is => 'ro', isa => 'Paws::CloudSearch::ExpressionStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DefineExpressionResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Expression => Paws::CloudSearch::ExpressionStatus

  


=cut

