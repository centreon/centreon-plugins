
package Paws::CognitoIdentity::DeleteIdentitiesResponse {
  use Moose;
  has UnprocessedIdentityIds => (is => 'ro', isa => 'ArrayRef[Paws::CognitoIdentity::UnprocessedIdentityId]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::DeleteIdentitiesResponse

=head1 ATTRIBUTES

=head2 UnprocessedIdentityIds => ArrayRef[Paws::CognitoIdentity::UnprocessedIdentityId]

  

An array of UnprocessedIdentityId objects, each of which contains an
ErrorCode and IdentityId.











=cut

1;