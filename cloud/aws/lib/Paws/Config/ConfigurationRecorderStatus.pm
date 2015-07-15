package Paws::Config::ConfigurationRecorderStatus {
  use Moose;
  has lastErrorCode => (is => 'ro', isa => 'Str');
  has lastErrorMessage => (is => 'ro', isa => 'Str');
  has lastStartTime => (is => 'ro', isa => 'Str');
  has lastStatus => (is => 'ro', isa => 'Str');
  has lastStatusChangeTime => (is => 'ro', isa => 'Str');
  has lastStopTime => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has recording => (is => 'ro', isa => 'Bool');
}
1;
