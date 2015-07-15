package Paws::ECS::ContainerDefinition {
  use Moose;
  has command => (is => 'ro', isa => 'ArrayRef[Str]');
  has cpu => (is => 'ro', isa => 'Int');
  has entryPoint => (is => 'ro', isa => 'ArrayRef[Str]');
  has environment => (is => 'ro', isa => 'ArrayRef[Paws::ECS::KeyValuePair]');
  has essential => (is => 'ro', isa => 'Bool');
  has image => (is => 'ro', isa => 'Str');
  has links => (is => 'ro', isa => 'ArrayRef[Str]');
  has memory => (is => 'ro', isa => 'Int');
  has mountPoints => (is => 'ro', isa => 'ArrayRef[Paws::ECS::MountPoint]');
  has name => (is => 'ro', isa => 'Str');
  has portMappings => (is => 'ro', isa => 'ArrayRef[Paws::ECS::PortMapping]');
  has volumesFrom => (is => 'ro', isa => 'ArrayRef[Paws::ECS::VolumeFrom]');
}
1;
