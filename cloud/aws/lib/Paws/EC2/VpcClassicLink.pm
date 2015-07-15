package Paws::EC2::VpcClassicLink {
  use Moose;
  has ClassicLinkEnabled => (is => 'ro', isa => 'Bool', xmlname => 'classicLinkEnabled', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
