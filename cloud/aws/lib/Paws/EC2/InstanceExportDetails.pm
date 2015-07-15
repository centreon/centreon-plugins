package Paws::EC2::InstanceExportDetails {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has TargetEnvironment => (is => 'ro', isa => 'Str', xmlname => 'targetEnvironment', traits => ['Unwrapped']);
}
1;
