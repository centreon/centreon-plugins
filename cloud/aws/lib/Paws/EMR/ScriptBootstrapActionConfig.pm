package Paws::EMR::ScriptBootstrapActionConfig {
  use Moose;
  has Args => (is => 'ro', isa => 'ArrayRef[Str]');
  has Path => (is => 'ro', isa => 'Str', required => 1);
}
1;
