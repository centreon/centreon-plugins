package Paws::SimpleWorkflow::RequestCancelActivityTaskDecisionAttributes {
  use Moose;
  has activityId => (is => 'ro', isa => 'Str', required => 1);
}
1;
