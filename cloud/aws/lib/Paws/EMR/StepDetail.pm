package Paws::EMR::StepDetail {
  use Moose;
  has ExecutionStatusDetail => (is => 'ro', isa => 'Paws::EMR::StepExecutionStatusDetail', required => 1);
  has StepConfig => (is => 'ro', isa => 'Paws::EMR::StepConfig', required => 1);
}
1;
