package Paws::Support::Communication {
  use Moose;
  has attachmentSet => (is => 'ro', isa => 'ArrayRef[Paws::Support::AttachmentDetails]');
  has body => (is => 'ro', isa => 'Str');
  has caseId => (is => 'ro', isa => 'Str');
  has submittedBy => (is => 'ro', isa => 'Str');
  has timeCreated => (is => 'ro', isa => 'Str');
}
1;
