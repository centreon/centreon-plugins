package Paws::OpsWorks::InstanceIdentity {
  use Moose;
  has Document => (is => 'ro', isa => 'Str');
  has Signature => (is => 'ro', isa => 'Str');
}
1;
