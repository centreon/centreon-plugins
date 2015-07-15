package Paws::OpsWorks::LifecycleEventConfiguration {
  use Moose;
  has Shutdown => (is => 'ro', isa => 'Paws::OpsWorks::ShutdownEventConfiguration');
}
1;
