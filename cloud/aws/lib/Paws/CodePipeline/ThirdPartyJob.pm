package Paws::CodePipeline::ThirdPartyJob {
  use Moose;
  has clientId => (is => 'ro', isa => 'Str');
  has jobId => (is => 'ro', isa => 'Str');
}
1;
