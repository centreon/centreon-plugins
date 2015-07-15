
package Paws::CloudSearch::DescribeExpressionsResponse {
  use Moose;
  has Expressions => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearch::ExpressionStatus]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeExpressionsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Expressions => ArrayRef[Paws::CloudSearch::ExpressionStatus]

  

The expressions configured for the domain.











=cut

