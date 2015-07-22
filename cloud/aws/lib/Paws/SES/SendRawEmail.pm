
package Paws::SES::SendRawEmail {
  use Moose;
  has Destinations => (is => 'ro', isa => 'ArrayRef[Str]');
  has FromArn => (is => 'ro', isa => 'Str');
  has RawMessage => (is => 'ro', isa => 'Paws::SES::RawMessage', required => 1);
  has ReturnPathArn => (is => 'ro', isa => 'Str');
  has Source => (is => 'ro', isa => 'Str');
  has SourceArn => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SendRawEmail');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::SendRawEmailResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SendRawEmailResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SendRawEmail - Arguments for method SendRawEmail on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method SendRawEmail on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method SendRawEmail.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SendRawEmail.

As an example:

  $service_obj->SendRawEmail(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Destinations => ArrayRef[Str]

  

A list of destinations for the message, consisting of To:, CC:, and
BCC: addresses.










=head2 FromArn => Str

  

This parameter is used only for sending authorization. It is the ARN of
the identity that is associated with the sending authorization policy
that permits you to specify a particular "From" address in the header
of the raw email.

Instead of using this parameter, you can use the X-header
C<X-SES-FROM-ARN> in the raw message of the email. If you use both the
C<FromArn> parameter and the corresponding X-header, Amazon SES uses
the value of the C<FromArn> parameter.

For information about when to use this parameter, see the description
of C<SendRawEmail> in this guide, or see the Amazon SES Developer
Guide.










=head2 B<REQUIRED> RawMessage => Paws::SES::RawMessage

  

The raw text of the message. The client is responsible for ensuring the
following:

=over

=item * Message must contain a header and a body, separated by a blank
line.

=item * All required header fields must be present.

=item * Each part of a multipart MIME message must be formatted
properly.

=item * MIME content types must be among those supported by Amazon SES.
For more information, go to the Amazon SES Developer Guide.

=item * Content must be base64-encoded, if MIME requires it.

=back










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

Instead of using this parameter, you can use the X-header
C<X-SES-RETURN-PATH-ARN> in the raw message of the email. If you use
both the C<ReturnPathArn> parameter and the corresponding X-header,
Amazon SES uses the value of the C<ReturnPathArn> parameter.

For information about when to use this parameter, see the description
of C<SendRawEmail> in this guide, or see the Amazon SES Developer
Guide.










=head2 Source => Str

  

The identity's email address. If you do not provide a value for this
parameter, you must specify a "From" address in the raw text of the
message. (You can also specify both.)

By default, the string must be 7-bit ASCII. If the text must contain
any other characters, then you must use MIME encoded-word syntax (RFC
2047) instead of a literal string. MIME encoded-word syntax uses the
following form: C<=?charset?encoding?encoded-text?=>. For more
information, see RFC 2047.

If you specify the C<Source> parameter and have feedback forwarding
enabled, then bounces and complaints will be sent to this email
address. This takes precedence over any I<Return-Path> header that you
might include in the raw text of the message.










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

Instead of using this parameter, you can use the X-header
C<X-SES-SOURCE-ARN> in the raw message of the email. If you use both
the C<SourceArn> parameter and the corresponding X-header, Amazon SES
uses the value of the C<SourceArn> parameter.

For information about when to use this parameter, see the description
of C<SendRawEmail> in this guide, or see the Amazon SES Developer
Guide.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SendRawEmail in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

