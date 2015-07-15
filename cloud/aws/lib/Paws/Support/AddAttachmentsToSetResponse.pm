
package Paws::Support::AddAttachmentsToSetResponse {
  use Moose;
  has attachmentSetId => (is => 'ro', isa => 'Str');
  has expiryTime => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::AddAttachmentsToSetResponse

=head1 ATTRIBUTES

=head2 attachmentSetId => Str

  

The ID of the attachment set. If an C<AttachmentSetId> was not
specified, a new attachment set is created, and the ID of the set is
returned in the response. If an C<AttachmentSetId> was specified, the
attachments are added to the specified set, if it exists.









=head2 expiryTime => Str

  

The time and date when the attachment set expires.











=cut

1;