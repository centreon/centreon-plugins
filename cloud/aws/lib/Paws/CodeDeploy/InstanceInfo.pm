package Paws::CodeDeploy::InstanceInfo {
  use Moose;
  has deregisterTime => (is => 'ro', isa => 'Str');
  has iamUserArn => (is => 'ro', isa => 'Str');
  has instanceArn => (is => 'ro', isa => 'Str');
  has instanceName => (is => 'ro', isa => 'Str');
  has registerTime => (is => 'ro', isa => 'Str');
  has tags => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::Tag]');
}
1;
