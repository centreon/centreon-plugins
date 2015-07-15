package Paws::Config::ConfigStreamDeliveryInfo {
  use Moose;
  has lastErrorCode => (is => 'ro', isa => 'Str');
  has lastErrorMessage => (is => 'ro', isa => 'Str');
  has lastStatus => (is => 'ro', isa => 'Str');
  has lastStatusChangeTime => (is => 'ro', isa => 'Str');
}
1;
