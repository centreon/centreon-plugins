package Paws::CloudFront::ActiveTrustedSigners {
  use Moose;
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
  has Items => (is => 'ro', isa => 'ArrayRef[Paws::CloudFront::Signer]');
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
