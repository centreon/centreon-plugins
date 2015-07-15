package Paws::StorageGateway::Disk {
  use Moose;
  has DiskAllocationResource => (is => 'ro', isa => 'Str');
  has DiskAllocationType => (is => 'ro', isa => 'Str');
  has DiskId => (is => 'ro', isa => 'Str');
  has DiskNode => (is => 'ro', isa => 'Str');
  has DiskPath => (is => 'ro', isa => 'Str');
  has DiskSizeInBytes => (is => 'ro', isa => 'Int');
  has DiskStatus => (is => 'ro', isa => 'Str');
}
1;
