
package Paws::Glacier::ListTagsForVaultOutput {
  use Moose;
  has Tags => (is => 'ro', isa => 'Paws::Glacier::TagMap');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::ListTagsForVaultOutput

=head1 ATTRIBUTES

=head2 Tags => Paws::Glacier::TagMap

  

The tags attached to the vault. Each tag is composed of a key and a
value.











=cut

