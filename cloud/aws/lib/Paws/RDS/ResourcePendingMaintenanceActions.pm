package Paws::RDS::ResourcePendingMaintenanceActions {
  use Moose;
  has PendingMaintenanceActionDetails => (is => 'ro', isa => 'ArrayRef[Paws::RDS::PendingMaintenanceAction]');
  has ResourceIdentifier => (is => 'ro', isa => 'Str');
}
1;
