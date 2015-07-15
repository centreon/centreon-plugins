package Paws::OpsWorks::ShutdownEventConfiguration {
  use Moose;
  has DelayUntilElbConnectionsDrained => (is => 'ro', isa => 'Bool');
  has ExecutionTimeout => (is => 'ro', isa => 'Int');
}
1;
