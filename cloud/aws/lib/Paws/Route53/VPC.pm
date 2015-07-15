package Paws::Route53::VPC {
  use Moose;
  has VPCId => (is => 'ro', isa => 'Str');
  has VPCRegion => (is => 'ro', isa => 'Str');
}
1;
