package Paws::Route53::ResourceRecordSet {
  use Moose;
  has AliasTarget => (is => 'ro', isa => 'Paws::Route53::AliasTarget');
  has Failover => (is => 'ro', isa => 'Str');
  has GeoLocation => (is => 'ro', isa => 'Paws::Route53::GeoLocation');
  has HealthCheckId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Region => (is => 'ro', isa => 'Str');
  has ResourceRecords => (is => 'ro', isa => 'ArrayRef[Paws::Route53::ResourceRecord]');
  has SetIdentifier => (is => 'ro', isa => 'Str');
  has TTL => (is => 'ro', isa => 'Int');
  has Type => (is => 'ro', isa => 'Str', required => 1);
  has Weight => (is => 'ro', isa => 'Int');
}
1;
