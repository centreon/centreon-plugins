package Paws::OpsWorks::ReportedOs {
  use Moose;
  has Family => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Version => (is => 'ro', isa => 'Str');
}
1;
