package Paws::DataPipeline::PipelineIdName {
  use Moose;
  has id => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
