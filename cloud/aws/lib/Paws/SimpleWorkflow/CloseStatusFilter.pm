package Paws::SimpleWorkflow::CloseStatusFilter {
  use Moose;
  has status => (is => 'ro', isa => 'Str', required => 1);
}
1;
