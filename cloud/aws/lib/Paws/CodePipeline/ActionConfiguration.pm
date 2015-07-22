package Paws::CodePipeline::ActionConfiguration {
  use Moose;
  has configuration => (is => 'ro', isa => 'Paws::CodePipeline::ActionConfigurationMap');
}
1;
