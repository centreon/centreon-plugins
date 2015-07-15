package Paws::Config::ConfigExportDeliveryInfo {
  use Moose;
  has lastAttemptTime => (is => 'ro', isa => 'Str');
  has lastErrorCode => (is => 'ro', isa => 'Str');
  has lastErrorMessage => (is => 'ro', isa => 'Str');
  has lastStatus => (is => 'ro', isa => 'Str');
  has lastSuccessfulTime => (is => 'ro', isa => 'Str');
}
1;
