package Paws::OpsWorks::Recipes {
  use Moose;
  has Configure => (is => 'ro', isa => 'ArrayRef[Str]');
  has Deploy => (is => 'ro', isa => 'ArrayRef[Str]');
  has Setup => (is => 'ro', isa => 'ArrayRef[Str]');
  has Shutdown => (is => 'ro', isa => 'ArrayRef[Str]');
  has Undeploy => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
