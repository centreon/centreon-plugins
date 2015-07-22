package Paws::IAM::SSHPublicKeyMetadata {
  use Moose;
  has SSHPublicKeyId => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has UploadDate => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str', required => 1);
}
1;
