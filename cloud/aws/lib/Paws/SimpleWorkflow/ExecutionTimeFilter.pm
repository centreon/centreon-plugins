package Paws::SimpleWorkflow::ExecutionTimeFilter {
  use Moose;
  has latestDate => (is => 'ro', isa => 'Str');
  has oldestDate => (is => 'ro', isa => 'Str', required => 1);
}
1;
