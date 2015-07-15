package Paws::ECS::VersionInfo {
  use Moose;
  has agentHash => (is => 'ro', isa => 'Str');
  has agentVersion => (is => 'ro', isa => 'Str');
  has dockerVersion => (is => 'ro', isa => 'Str');
}
1;
