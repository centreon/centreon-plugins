package Paws::ECS::Container {
  use Moose;
  has containerArn => (is => 'ro', isa => 'Str');
  has exitCode => (is => 'ro', isa => 'Int');
  has lastStatus => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has networkBindings => (is => 'ro', isa => 'ArrayRef[Paws::ECS::NetworkBinding]');
  has reason => (is => 'ro', isa => 'Str');
  has taskArn => (is => 'ro', isa => 'Str');
}
1;
