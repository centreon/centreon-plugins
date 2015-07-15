package Paws::OpsWorks::StackConfigurationManager {
  use Moose;
  has Name => (is => 'ro', isa => 'Str');
  has Version => (is => 'ro', isa => 'Str');
}
1;
