package Paws::EMR::StepConfig {
  use Moose;
  has ActionOnFailure => (is => 'ro', isa => 'Str');
  has HadoopJarStep => (is => 'ro', isa => 'Paws::EMR::HadoopJarStepConfig', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);
}
1;
