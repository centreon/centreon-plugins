package Paws::CodePipeline::ActionExecution {
  use Moose;
  has errorDetails => (is => 'ro', isa => 'Paws::CodePipeline::ErrorDetails');
  has externalExecutionId => (is => 'ro', isa => 'Str');
  has externalExecutionUrl => (is => 'ro', isa => 'Str');
  has lastStatusChange => (is => 'ro', isa => 'Str');
  has percentComplete => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
  has summary => (is => 'ro', isa => 'Str');
}
1;
