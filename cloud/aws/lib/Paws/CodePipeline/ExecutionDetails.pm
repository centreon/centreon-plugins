package Paws::CodePipeline::ExecutionDetails {
  use Moose;
  has externalExecutionId => (is => 'ro', isa => 'Str');
  has percentComplete => (is => 'ro', isa => 'Int');
  has summary => (is => 'ro', isa => 'Str');
}
1;
