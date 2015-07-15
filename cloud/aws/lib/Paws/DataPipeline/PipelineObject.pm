package Paws::DataPipeline::PipelineObject {
  use Moose;
  has fields => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::Field]', required => 1);
  has id => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
}
1;
