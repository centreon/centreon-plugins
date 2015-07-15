package Paws::EC2::IpPermission {
  use Moose;
  has FromPort => (is => 'ro', isa => 'Int', xmlname => 'fromPort', traits => ['Unwrapped']);
  has IpProtocol => (is => 'ro', isa => 'Str', xmlname => 'ipProtocol', traits => ['Unwrapped']);
  has IpRanges => (is => 'ro', isa => 'ArrayRef[Paws::EC2::IpRange]', xmlname => 'ipRanges', traits => ['Unwrapped']);
  has PrefixListIds => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PrefixListId]', xmlname => 'prefixListIds', traits => ['Unwrapped']);
  has ToPort => (is => 'ro', isa => 'Int', xmlname => 'toPort', traits => ['Unwrapped']);
  has UserIdGroupPairs => (is => 'ro', isa => 'ArrayRef[Paws::EC2::UserIdGroupPair]', xmlname => 'groups', traits => ['Unwrapped']);
}
1;
