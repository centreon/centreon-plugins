package Paws::SES::IdentityVerificationAttributes {
  use Moose;
  has VerificationStatus => (is => 'ro', isa => 'Str', required => 1);
  has VerificationToken => (is => 'ro', isa => 'Str');
}
1;
