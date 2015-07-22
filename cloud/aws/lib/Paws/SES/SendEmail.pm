
package Paws::SES::SendEmail {
  use Moose;
  has Destination => (is => 'ro', isa => 'Paws::SES::Destination', required => 1);
  has Message => (is => 'ro', isa => 'Paws::SES::Message', required => 1);
  has ReplyToAddresses => (is => 'ro', isa => 'ArrayRef[Str]');
  has ReturnPath => (is => 'ro', isa => 'Str');
  has ReturnPathArn => (is => 'ro', isa => 'Str');
  has Source => (is => 'ro', isa => 'Str', required => 1);
  has SourceArn => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SendEmail');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::SendEmailResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SendEmailResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SendEmail - Arguments for method SendEmail on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method SendEmail on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method SendEmail.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SendEmail.

As an example:

  $service_obj->SendEmail(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Destination => Paws::SES::Destination

  

The destination for this email, composed of To:, CC:, and BCC: fields.










=head2 B<REQUIRED> Message => Paws::SES::Message

  

The message to be sent.










=head2 ReplyToAddresses => ArrayRef[Str]

  

The reply-to email address(es) for the message. If the recipient
replies to the message, each reply-to address will receive the reply.










=head2 ReturnPath => Str

  

The email address to which bounces and complaints are to be forwarded
when feedback forwarding is enabled. If the message cannot be delivered
to the recipient, then an error message will be returned from the
recipient's ISP; this message will then be forwarded to the email
address specified by the C<ReturnPath> parameter. The C<ReturnPath>
parameter is never overwritten. This email address must be either
individually verified with Amazon SES, or from a domain that has been
verified with Amazon SES.










=head2 ReturnPathArn => Str

  

This parameter is used only for sending authorization. It is the ARN of
the identity that is associated with the sending authorization policy
that permits you to use the email address specified in the
C<ReturnPath> parameter.

For example, if the owner of C<example.com> (which has ARN
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>) attaches a
policy to it that authorizes you to use C<feedback@example.com>, then
you would specify the C<ReturnPathArn> to be
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>, and the
C<ReturnPath> to be C<feedback@example.com>.

For more information about sending authorization, see the Amazon SES
Developer Guide.










=head2 B<REQUIRED> Source => Str

  

The email address that is sending the email. This email address must be
either individually verified with Amazon SES, or from a domain that has
been verified with Amazon SES. For information about verifying
identities, see the Amazon SES Developer Guide.

If you are sending on behalf of another user and have been permitted to
do so by a sending authorization policy, then you must also specify the
C<SourceArn> parameter. For more information about sending
authorization, see the Amazon SES Developer Guide.

In all cases, the email address must be 7-bit ASCII. If the text must
contain any other characters, then you must use MIME encoded-word
syntax (RFC 2047) instead of a literal string. MIME encoded-word syntax
uses the following form: C<=?charset?encoding?encoded-text?=>. For more
information, see RFC 2047.










=head2 SourceArn => Str

  

This parameter is used only for sending authorization. It is the ARN of
the identity that is associated with the sending authorization policy
that permits you to send for the email address specified in the
C<Source> parameter.

For example, if the owner of C<example.com> (which has ARN
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>) attaches a
policy to it that authorizes you to send from C<user@example.com>, then
you would specify the C<SourceArn> to be
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>, and the
C<Source> to be C<user@example.com>.

For more information about sending authorization, see the Amazon SES
Developer Guide.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SendEmail in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

