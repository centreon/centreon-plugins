package Paws::SES::IdentityDkimAttributes {
  use Moose;
  has DkimEnabled => (is => 'ro', isa => 'Bool', required => 1);
  has DkimTokens => (is => 'ro', isa => 'ArrayRef[Str]');
  has DkimVerificationStatus => (is => 'ro', isa => 'Str', required => 1);
}
1;
