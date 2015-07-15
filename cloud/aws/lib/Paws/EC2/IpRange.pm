package Paws::EC2::IpRange {
  use Moose;
  has CidrIp => (is => 'ro', isa => 'Str', xmlname => 'cidrIp', traits => ['Unwrapped']);
}
1;
