package Paws::SSM::AssociationDescription {
  use Moose;
  has Date => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Paws::SSM::AssociationStatus');
}
1;
