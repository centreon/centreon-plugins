package Paws::AutoScaling::ProcessType {
  use Moose;
  has ProcessName => (is => 'ro', isa => 'Str', required => 1);
}
1;
