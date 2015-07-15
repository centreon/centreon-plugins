
package Paws::CognitoIdentity::ListIdentitiesResponse {
  use Moose;
  has Identities => (is => 'ro', isa => 'ArrayRef[Paws::CognitoIdentity::IdentityDescription]');
  has IdentityPoolId => (is => 'ro', isa => 'Str');
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::ListIdentitiesResponse

=head1 ATTRIBUTES

=head2 Identities => ArrayRef[Paws::CognitoIdentity::IdentityDescription]

  

An object containing a set of identities and associated mappings.









=head2 IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.









=head2 NextToken => Str

  

A pagination token.











=cut

1;