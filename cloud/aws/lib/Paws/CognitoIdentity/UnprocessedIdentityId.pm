package Paws::CognitoIdentity::UnprocessedIdentityId {
  use Moose;
  has ErrorCode => (is => 'ro', isa => 'Str');
  has IdentityId => (is => 'ro', isa => 'Str');
}
1;
