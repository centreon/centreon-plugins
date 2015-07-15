package Paws::SimpleWorkflow::WorkflowTypeFilter {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
  has version => (is => 'ro', isa => 'Str');
}
1;
