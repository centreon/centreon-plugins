package Paws::CodePipeline::FailureDetails {
  use Moose;
  has externalExecutionId => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str', required => 1);
}
1;
