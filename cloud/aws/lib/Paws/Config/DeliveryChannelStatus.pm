package Paws::Config::DeliveryChannelStatus {
  use Moose;
  has configHistoryDeliveryInfo => (is => 'ro', isa => 'Paws::Config::ConfigExportDeliveryInfo');
  has configSnapshotDeliveryInfo => (is => 'ro', isa => 'Paws::Config::ConfigExportDeliveryInfo');
  has configStreamDeliveryInfo => (is => 'ro', isa => 'Paws::Config::ConfigStreamDeliveryInfo');
  has name => (is => 'ro', isa => 'Str');
}
1;
