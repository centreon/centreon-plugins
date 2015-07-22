package Paws::CodePipeline::PipelineContext {
  use Moose;
  has action => (is => 'ro', isa => 'Paws::CodePipeline::ActionContext');
  has pipelineName => (is => 'ro', isa => 'Str');
  has stage => (is => 'ro', isa => 'Paws::CodePipeline::StageContext');
}
1;
