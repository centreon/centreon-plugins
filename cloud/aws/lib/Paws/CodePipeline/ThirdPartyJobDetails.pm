package Paws::CodePipeline::ThirdPartyJobDetails {
  use Moose;
  has data => (is => 'ro', isa => 'Paws::CodePipeline::ThirdPartyJobData');
  has id => (is => 'ro', isa => 'Str');
  has nonce => (is => 'ro', isa => 'Str');
}
1;
