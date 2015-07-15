package Paws::OpsWorks::AgentVersion {
  use Moose;
  has ConfigurationManager => (is => 'ro', isa => 'Paws::OpsWorks::StackConfigurationManager');
  has Version => (is => 'ro', isa => 'Str');
}
1;
