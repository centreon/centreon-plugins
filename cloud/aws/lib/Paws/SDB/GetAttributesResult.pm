
package Paws::SDB::GetAttributesResult {
  use Moose;
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::SDB::Attribute]', xmlname => 'Attribute', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::GetAttributesResult

=head1 ATTRIBUTES

=head2 Attributes => ArrayRef[Paws::SDB::Attribute]

  

The list of attributes returned by the operation.











=cut

