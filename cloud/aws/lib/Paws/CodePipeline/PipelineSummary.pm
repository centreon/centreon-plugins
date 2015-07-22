package Paws::CodePipeline::PipelineSummary {
  use Moose;
  has created => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has updated => (is => 'ro', isa => 'Str');
  has version => (is => 'ro', isa => 'Int');
}
1;
