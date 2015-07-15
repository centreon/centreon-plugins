
package Paws::SES::SendEmail {
  use Moose;
  has Destination => (is => 'ro', isa => 'Paws::SES::Destination', required => 1);
  has Message => (is => 'ro', isa => 'Paws::SES::Message', required => 1);
  has ReplyToAddresses => (is => 'ro', isa => 'ArrayRef[Str]');
  has ReturnPath => (is => 'ro', isa => 'Str');
  has Source => (is => 'ro', isa => 'Str', required => 1);

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










=head2 B<REQUIRED> Source => Str

  

The identity's email address.

By default, the string must be 7-bit ASCII. If the text must contain
any other characters, then you must use MIME encoded-word syntax (RFC
2047) instead of a literal string. MIME encoded-word syntax uses the
following form: C<=?charset?encoding?encoded-text?=>. For more
information, see RFC 2047.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SendEmail in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

