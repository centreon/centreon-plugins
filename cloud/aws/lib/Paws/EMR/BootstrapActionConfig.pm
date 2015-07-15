package Paws::EMR::BootstrapActionConfig {
  use Moose;
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has ScriptBootstrapAction => (is => 'ro', isa => 'Paws::EMR::ScriptBootstrapActionConfig', required => 1);
}
1;
