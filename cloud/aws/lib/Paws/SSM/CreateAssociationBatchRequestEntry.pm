package Paws::SSM::CreateAssociationBatchRequestEntry {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
}
1;
