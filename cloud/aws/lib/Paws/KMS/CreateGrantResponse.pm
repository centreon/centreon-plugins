
package Paws::KMS::CreateGrantResponse {
  use Moose;
  has GrantId => (is => 'ro', isa => 'Str');
  has GrantToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::CreateGrantResponse

=head1 ATTRIBUTES

=head2 GrantId => Str

  

Unique grant identifier. You can use the I<GrantId> value to revoke a
grant.









=head2 GrantToken => Str

  

For more information, see Grant Tokens.











=cut

1;