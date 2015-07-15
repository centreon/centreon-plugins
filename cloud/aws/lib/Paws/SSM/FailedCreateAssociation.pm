package Paws::SSM::FailedCreateAssociation {
  use Moose;
  has Entry => (is => 'ro', isa => 'Paws::SSM::CreateAssociationBatchRequestEntry');
  has Fault => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
}
1;
