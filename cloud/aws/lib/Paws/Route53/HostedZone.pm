package Paws::Route53::HostedZone {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has Config => (is => 'ro', isa => 'Paws::Route53::HostedZoneConfig');
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has ResourceRecordSetCount => (is => 'ro', isa => 'Int');
}
1;
