package Paws::Route53Domains::Nameserver {
  use Moose;
  has GlueIps => (is => 'ro', isa => 'ArrayRef[Str]');
  has Name => (is => 'ro', isa => 'Str', required => 1);
}
1;
