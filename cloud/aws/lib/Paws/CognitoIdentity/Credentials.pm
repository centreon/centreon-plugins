package Paws::CognitoIdentity::Credentials {
  use Moose;
  has AccessKeyId => (is => 'ro', isa => 'Str');
  has Expiration => (is => 'ro', isa => 'Str');
  has SecretKey => (is => 'ro', isa => 'Str');
  has SessionToken => (is => 'ro', isa => 'Str');
}
1;
