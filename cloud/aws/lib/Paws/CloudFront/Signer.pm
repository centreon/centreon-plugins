package Paws::CloudFront::Signer {
  use Moose;
  has AwsAccountNumber => (is => 'ro', isa => 'Str');
  has KeyPairIds => (is => 'ro', isa => 'Paws::CloudFront::KeyPairIds');
}
1;
