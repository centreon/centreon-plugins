package Paws::DeviceFarm::UniqueProblemsByExecutionResultMap {
  use Moose;
  with 'Paws::API::MapParser';

  use MooseX::ClassAttribute;
  class_has xml_keys =>(is => 'ro', default => 'key');
  class_has xml_values =>(is => 'ro', default => 'value');

  has ERRORED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has FAILED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has PASSED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has PENDING => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has SKIPPED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has STOPPED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
  has WARNED => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::UniqueProblem]');
}
1
