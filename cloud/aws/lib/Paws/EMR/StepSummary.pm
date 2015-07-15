package Paws::EMR::StepSummary {
  use Moose;
  has ActionOnFailure => (is => 'ro', isa => 'Str');
  has Config => (is => 'ro', isa => 'Paws::EMR::HadoopStepConfig');
  has Id => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Paws::EMR::StepStatus');
}
1;
