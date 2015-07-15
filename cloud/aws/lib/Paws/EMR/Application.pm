package Paws::EMR::Application {
  use Moose;
  has AdditionalInfo => (is => 'ro', isa => 'Paws::EMR::StringMap');
  has Args => (is => 'ro', isa => 'ArrayRef[Str]');
  has Name => (is => 'ro', isa => 'Str');
  has Version => (is => 'ro', isa => 'Str');
}
1;
