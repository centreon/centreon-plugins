package Paws::Route53Domains::DomainSummary {
  use Moose;
  has AutoRenew => (is => 'ro', isa => 'Bool');
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Expiry => (is => 'ro', isa => 'Str');
  has TransferLock => (is => 'ro', isa => 'Bool');
}
1;
