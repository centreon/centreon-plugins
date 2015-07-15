
package Paws::SSM::CreateAssociationBatchResult {
  use Moose;
  has Failed => (is => 'ro', isa => 'ArrayRef[Paws::SSM::FailedCreateAssociation]');
  has Successful => (is => 'ro', isa => 'ArrayRef[Paws::SSM::AssociationDescription]');

}

### main pod documentation begin ###

=head1 NAME

Paws::SSM::CreateAssociationBatchResult

=head1 ATTRIBUTES

=head2 Failed => ArrayRef[Paws::SSM::FailedCreateAssociation]

  

Information about the associations that failed.









=head2 Successful => ArrayRef[Paws::SSM::AssociationDescription]

  

Information about the associations that succeeded.











=cut

1;