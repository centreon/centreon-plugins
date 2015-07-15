
package Paws::SNS::Publish {
  use Moose;
  has Message => (is => 'ro', isa => 'Str', required => 1);
  has MessageAttributes => (is => 'ro', isa => 'Paws::SNS::MessageAttributeMap');
  has MessageStructure => (is => 'ro', isa => 'Str');
  has Subject => (is => 'ro', isa => 'Str');
  has TargetArn => (is => 'ro', isa => 'Str');
  has TopicArn => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Publish');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::PublishResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'PublishResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::Publish - Arguments for method Publish on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method Publish on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method Publish.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Publish.

As an example:

  $service_obj->Publish(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Message => Str

  

The message you want to send to the topic.

If you want to send the same message to all transport protocols,
include the text of the message as a String value.

If you want to send different messages for each transport protocol, set
the value of the C<MessageStructure> parameter to C<json> and use a
JSON object for the C<Message> parameter. See the Examples section for
the format of the JSON object.

Constraints: Messages must be UTF-8 encoded strings at most 256 KB in
size (262144 bytes, not 262144 characters).

JSON-specific constraints:

=over

=item * Keys in the JSON object that correspond to supported transport
protocols must have simple JSON string values.

=item * The values will be parsed (unescaped) before they are used in
outgoing messages.

=item * Outbound notifications are JSON encoded (meaning that the
characters will be reescaped for sending).

=item * Values have a minimum length of 0 (the empty string, "", is
allowed).

=item * Values have a maximum length bounded by the overall message
size (so, including multiple protocols may limit message sizes).

=item * Non-string values will cause the key to be ignored.

=item * Keys that do not correspond to supported transport protocols
are ignored.

=item * Duplicate keys are not allowed.

=item * Failure to parse or validate any key or value in the message
will cause the C<Publish> call to return an error (no partial
delivery).

=back










=head2 MessageAttributes => Paws::SNS::MessageAttributeMap

  

Message attributes for Publish action.










=head2 MessageStructure => Str

  

Set C<MessageStructure> to C<json> if you want to send a different
message for each protocol. For example, using one publish action, you
can send a short message to your SMS subscribers and a longer message
to your email subscribers. If you set C<MessageStructure> to C<json>,
the value of the C<Message> parameter must:

=over

=item * be a syntactically valid JSON object; and

=item * contain at least a top-level JSON key of "default" with a value
that is a string.

=back

You can define other top-level keys that define the message you want to
send to a specific transport protocol (e.g., "http").

For information about sending different messages for each protocol
using the AWS Management Console, go to Create Different Messages for
Each Protocol in the I<Amazon Simple Notification Service Getting
Started Guide>.

Valid value: C<json>










=head2 Subject => Str

  

Optional parameter to be used as the "Subject" line when the message is
delivered to email endpoints. This field will also be included, if
present, in the standard JSON messages delivered to other endpoints.

Constraints: Subjects must be ASCII text that begins with a letter,
number, or punctuation mark; must not include line breaks or control
characters; and must be less than 100 characters long.










=head2 TargetArn => Str

  

Either TopicArn or EndpointArn, but not both.










=head2 TopicArn => Str

  

The topic you want to publish to.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Publish in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

