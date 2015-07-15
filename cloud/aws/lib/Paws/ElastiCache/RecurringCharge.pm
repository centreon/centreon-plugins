package Paws::ElastiCache::RecurringCharge {
  use Moose;
  has RecurringChargeAmount => (is => 'ro', isa => 'Num');
  has RecurringChargeFrequency => (is => 'ro', isa => 'Str');
}
1;
