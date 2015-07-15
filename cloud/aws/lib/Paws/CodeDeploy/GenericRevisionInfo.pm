package Paws::CodeDeploy::GenericRevisionInfo {
  use Moose;
  has deploymentGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has description => (is => 'ro', isa => 'Str');
  has firstUsedTime => (is => 'ro', isa => 'Str');
  has lastUsedTime => (is => 'ro', isa => 'Str');
  has registerTime => (is => 'ro', isa => 'Str');
}
1;
