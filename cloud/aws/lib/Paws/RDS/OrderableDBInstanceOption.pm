package Paws::RDS::OrderableDBInstanceOption {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Paws::RDS::AvailabilityZone]');
  has DBInstanceClass => (is => 'ro', isa => 'Str');
  has Engine => (is => 'ro', isa => 'Str');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has LicenseModel => (is => 'ro', isa => 'Str');
  has MultiAZCapable => (is => 'ro', isa => 'Bool');
  has ReadReplicaCapable => (is => 'ro', isa => 'Bool');
  has StorageType => (is => 'ro', isa => 'Str');
  has SupportsIops => (is => 'ro', isa => 'Bool');
  has SupportsStorageEncryption => (is => 'ro', isa => 'Bool');
  has Vpc => (is => 'ro', isa => 'Bool');
}
1;
