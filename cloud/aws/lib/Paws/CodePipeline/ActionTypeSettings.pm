package Paws::CodePipeline::ActionTypeSettings {
  use Moose;
  has entityUrlTemplate => (is => 'ro', isa => 'Str');
  has executionUrlTemplate => (is => 'ro', isa => 'Str');
  has revisionUrlTemplate => (is => 'ro', isa => 'Str');
  has thirdPartyConfigurationUrl => (is => 'ro', isa => 'Str');
}
1;
