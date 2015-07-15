package Paws::EC2::HistoryRecord {
  use Moose;
  has EventInformation => (is => 'ro', isa => 'Paws::EC2::EventInformation', xmlname => 'eventInformation', traits => ['Unwrapped'], required => 1);
  has EventType => (is => 'ro', isa => 'Str', xmlname => 'eventType', traits => ['Unwrapped'], required => 1);
  has Timestamp => (is => 'ro', isa => 'Str', xmlname => 'timestamp', traits => ['Unwrapped'], required => 1);
}
1;
