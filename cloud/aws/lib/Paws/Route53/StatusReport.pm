package Paws::Route53::StatusReport {
  use Moose;
  has CheckedTime => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
