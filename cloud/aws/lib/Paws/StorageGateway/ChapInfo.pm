package Paws::StorageGateway::ChapInfo {
  use Moose;
  has InitiatorName => (is => 'ro', isa => 'Str');
  has SecretToAuthenticateInitiator => (is => 'ro', isa => 'Str');
  has SecretToAuthenticateTarget => (is => 'ro', isa => 'Str');
  has TargetARN => (is => 'ro', isa => 'Str');
}
1;
