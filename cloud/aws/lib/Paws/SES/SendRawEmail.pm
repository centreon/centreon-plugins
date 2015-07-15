
package Paws::SES::SendRawEmail {
  use Moose;
  has Destinations => (is => 'ro', isa => 'ArrayRef[Str]');
  has RawMessage => (is => 'ro', isa => 'Paws::SES::RawMessage', required => 1);
  has Source => (is => 'ro', isa => 'Str');

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












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SendRawEmail in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

