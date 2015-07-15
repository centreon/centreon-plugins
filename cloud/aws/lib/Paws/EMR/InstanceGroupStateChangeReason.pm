package Paws::EMR::InstanceGroupStateChangeReason {
  use Moose;
  has Code => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
}
1;
