package Paws::SimpleWorkflow::TaskList {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
}
1;
