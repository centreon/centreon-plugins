package Paws::CodePipeline::Job {
  use Moose;
  has accountId => (is => 'ro', isa => 'Str');
  has data => (is => 'ro', isa => 'Paws::CodePipeline::JobData');
  has id => (is => 'ro', isa => 'Str');
  has nonce => (is => 'ro', isa => 'Str');
}
1;
