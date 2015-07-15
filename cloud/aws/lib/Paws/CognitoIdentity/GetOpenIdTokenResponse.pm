
package Paws::CognitoIdentity::GetOpenIdTokenResponse {
  use Moose;
  has IdentityId => (is => 'ro', isa => 'Str');
  has Token => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::GetOpenIdTokenResponse

=head1 ATTRIBUTES

=head2 IdentityId => Str

  

A unique identifier in the format REGION:GUID. Note that the IdentityId
returned may not match the one passed on input.









=head2 Token => Str

  

An OpenID token, valid for 15 minutes.











=cut

1;