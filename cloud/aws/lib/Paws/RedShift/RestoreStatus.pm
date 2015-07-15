package Paws::RedShift::RestoreStatus {
  use Moose;
  has CurrentRestoreRateInMegaBytesPerSecond => (is => 'ro', isa => 'Num');
  has ElapsedTimeInSeconds => (is => 'ro', isa => 'Int');
  has EstimatedTimeToCompletionInSeconds => (is => 'ro', isa => 'Int');
  has ProgressInMegaBytes => (is => 'ro', isa => 'Int');
  has SnapshotSizeInMegaBytes => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Str');
}
1;
