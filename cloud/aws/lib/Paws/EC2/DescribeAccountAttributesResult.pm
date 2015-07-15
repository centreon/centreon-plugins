
package Paws::EC2::DescribeAccountAttributesResult {
  use Moose;
  has AccountAttributes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::AccountAttribute]', xmlname => 'accountAttributeSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeAccountAttributesResult

=head1 ATTRIBUTES

=head2 AccountAttributes => ArrayRef[Paws::EC2::AccountAttribute]

  

Information about one or more account attributes.











=cut

