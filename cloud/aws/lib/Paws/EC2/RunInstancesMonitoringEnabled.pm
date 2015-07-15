package Paws::EC2::RunInstancesMonitoringEnabled {
  use Moose;
  has Enabled => (is => 'ro', isa => 'Bool', xmlname => 'enabled', traits => ['Unwrapped'], required => 1);
}
1;
