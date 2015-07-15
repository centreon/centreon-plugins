package Paws::SimpleWorkflow::ActivityType {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
  has version => (is => 'ro', isa => 'Str', required => 1);
}
1;
