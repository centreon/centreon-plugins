package Paws::EMR::BootstrapActionDetail {
  use Moose;
  has BootstrapActionConfig => (is => 'ro', isa => 'Paws::EMR::BootstrapActionConfig');
}
1;
