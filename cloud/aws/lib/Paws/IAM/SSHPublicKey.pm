package Paws::IAM::SSHPublicKey {
  use Moose;
  has Fingerprint => (is => 'ro', isa => 'Str', required => 1);
  has SSHPublicKeyBody => (is => 'ro', isa => 'Str', required => 1);
  has SSHPublicKeyId => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has UploadDate => (is => 'ro', isa => 'Str');
  has UserName => (is => 'ro', isa => 'Str', required => 1);
}
1;
