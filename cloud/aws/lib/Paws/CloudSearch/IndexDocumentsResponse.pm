
package Paws::CloudSearch::IndexDocumentsResponse {
  use Moose;
  has FieldNames => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::IndexDocumentsResponse

=head1 ATTRIBUTES

=head2 FieldNames => ArrayRef[Str]

  

The names of the fields that are currently being indexed.











=cut

