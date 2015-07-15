package Paws::Route53Domains::OperationSummary {
  use Moose;
  has OperationId => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has SubmittedDate => (is => 'ro', isa => 'Str', required => 1);
  has Type => (is => 'ro', isa => 'Str', required => 1);
}
1;
