package Paws::OpsWorks::InstancesCount {
  use Moose;
  has Assigning => (is => 'ro', isa => 'Int');
  has Booting => (is => 'ro', isa => 'Int');
  has ConnectionLost => (is => 'ro', isa => 'Int');
  has Deregistering => (is => 'ro', isa => 'Int');
  has Online => (is => 'ro', isa => 'Int');
  has Pending => (is => 'ro', isa => 'Int');
  has Rebooting => (is => 'ro', isa => 'Int');
  has Registered => (is => 'ro', isa => 'Int');
  has Registering => (is => 'ro', isa => 'Int');
  has Requested => (is => 'ro', isa => 'Int');
  has RunningSetup => (is => 'ro', isa => 'Int');
  has SetupFailed => (is => 'ro', isa => 'Int');
  has ShuttingDown => (is => 'ro', isa => 'Int');
  has StartFailed => (is => 'ro', isa => 'Int');
  has Stopped => (is => 'ro', isa => 'Int');
  has Stopping => (is => 'ro', isa => 'Int');
  has Terminated => (is => 'ro', isa => 'Int');
  has Terminating => (is => 'ro', isa => 'Int');
  has Unassigning => (is => 'ro', isa => 'Int');
}
1;
