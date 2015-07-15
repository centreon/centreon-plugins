
package Paws::Support::DescribeAttachment {
  use Moose;
  has attachmentId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeAttachment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::DescribeAttachmentResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeAttachment - Arguments for method DescribeAttachment on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeAttachment on the 
AWS Support service. Use the attributes of this class
as arguments to method DescribeAttachment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeAttachment.

As an example:

  $service_obj->DescribeAttachment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> attachmentId => Str

  

The ID of the attachment to return. Attachment IDs are returned by the
DescribeCommunications operation.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeAttachment in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

