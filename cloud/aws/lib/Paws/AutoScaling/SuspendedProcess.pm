package Paws::AutoScaling::SuspendedProcess {
  use Moose;
  has ProcessName => (is => 'ro', isa => 'Str');
  has SuspensionReason => (is => 'ro', isa => 'Str');
}
1;
