package Paws::EMR::HadoopStepConfig {
  use Moose;
  has Args => (is => 'ro', isa => 'ArrayRef[Str]');
  has Jar => (is => 'ro', isa => 'Str');
  has MainClass => (is => 'ro', isa => 'Str');
  has Properties => (is => 'ro', isa => 'Paws::EMR::StringMap');
}
1;
