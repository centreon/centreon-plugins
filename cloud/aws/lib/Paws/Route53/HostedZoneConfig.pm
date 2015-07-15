package Paws::Route53::HostedZoneConfig {
  use Moose;
  has Comment => (is => 'ro', isa => 'Str');
  has PrivateZone => (is => 'ro', isa => 'Bool');
}
1;
