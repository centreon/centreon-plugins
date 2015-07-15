package Paws::CognitoIdentity::IdentityPoolShortDescription {
  use Moose;
  has IdentityPoolId => (is => 'ro', isa => 'Str');
  has IdentityPoolName => (is => 'ro', isa => 'Str');
}
1;
