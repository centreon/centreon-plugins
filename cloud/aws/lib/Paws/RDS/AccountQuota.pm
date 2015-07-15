package Paws::RDS::AccountQuota {
  use Moose;
  has AccountQuotaName => (is => 'ro', isa => 'Str');
  has Max => (is => 'ro', isa => 'Int');
  has Used => (is => 'ro', isa => 'Int');
}
1;
