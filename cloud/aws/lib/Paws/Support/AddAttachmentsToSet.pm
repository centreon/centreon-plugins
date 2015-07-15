
package Paws::Support::AddAttachmentsToSet {
  use Moose;
  has attachments => (is => 'ro', isa => 'ArrayRef[Paws::Support::Attachment]', required => 1);
  has attachmentSetId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddAttachmentsToSet');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::AddAttachmentsToSetResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::AddAttachmentsToSet - Arguments for method AddAttachmentsToSet on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddAttachmentsToSet on the 
AWS Support service. Use the attributes of this class
as arguments to method AddAttachmentsToSet.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddAttachmentsToSet.

As an example:

  $service_obj->AddAttachmentsToSet(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> attachments => ArrayRef[Paws::Support::Attachment]

  

One or more attachments to add to the set. The limit is 3 attachments
per set, and the size limit is 5 MB per attachment.










=head2 attachmentSetId => Str

  

The ID of the attachment set. If an C<AttachmentSetId> is not
specified, a new attachment set is created, and the ID of the set is
returned in the response. If an C<AttachmentSetId> is specified, the
attachments are added to the specified set, if it exists.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddAttachmentsToSet in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

