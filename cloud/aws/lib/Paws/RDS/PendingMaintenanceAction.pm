package Paws::RDS::PendingMaintenanceAction {
  use Moose;
  has Action => (is => 'ro', isa => 'Str');
  has AutoAppliedAfterDate => (is => 'ro', isa => 'Str');
  has CurrentApplyDate => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has ForcedApplyDate => (is => 'ro', isa => 'Str');
  has OptInStatus => (is => 'ro', isa => 'Str');
}
1;
