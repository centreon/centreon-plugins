
package Paws::SSM::ListAssociationsResult {
  use Moose;
  has Associations => (is => 'ro', isa => 'ArrayRef[Paws::SSM::Association]');
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::SSM::ListAssociationsResult

=head1 ATTRIBUTES

=head2 Associations => ArrayRef[Paws::SSM::Association]

  

The associations.









=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.











=cut

1;