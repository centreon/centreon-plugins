package Paws::EC2::NetworkAclEntry {
  use Moose;
  has CidrBlock => (is => 'ro', isa => 'Str', xmlname => 'cidrBlock', traits => ['Unwrapped']);
  has Egress => (is => 'ro', isa => 'Bool', xmlname => 'egress', traits => ['Unwrapped']);
  has IcmpTypeCode => (is => 'ro', isa => 'Paws::EC2::IcmpTypeCode', xmlname => 'icmpTypeCode', traits => ['Unwrapped']);
  has PortRange => (is => 'ro', isa => 'Paws::EC2::PortRange', xmlname => 'portRange', traits => ['Unwrapped']);
  has Protocol => (is => 'ro', isa => 'Str', xmlname => 'protocol', traits => ['Unwrapped']);
  has RuleAction => (is => 'ro', isa => 'Str', xmlname => 'ruleAction', traits => ['Unwrapped']);
  has RuleNumber => (is => 'ro', isa => 'Int', xmlname => 'ruleNumber', traits => ['Unwrapped']);
}
1;
