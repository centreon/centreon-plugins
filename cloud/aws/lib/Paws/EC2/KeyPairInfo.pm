package Paws::EC2::KeyPairInfo {
  use Moose;
  has KeyFingerprint => (is => 'ro', isa => 'Str', xmlname => 'keyFingerprint', traits => ['Unwrapped']);
  has KeyName => (is => 'ro', isa => 'Str', xmlname => 'keyName', traits => ['Unwrapped']);
}
1;
