
package Paws::SQS::ReceiveMessage {
  use Moose;
  has AttributeNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has MaxNumberOfMessages => (is => 'ro', isa => 'Int');
  has MessageAttributeNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);
  has VisibilityTimeout => (is => 'ro', isa => 'Int');
  has WaitTimeSeconds => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ReceiveMessage');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SQS::ReceiveMessageResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ReceiveMessageResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::ReceiveMessage - Arguments for method ReceiveMessage on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ReceiveMessage on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method ReceiveMessage.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ReceiveMessage.

As an example:

  $service_obj->ReceiveMessage(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AttributeNames => ArrayRef[Str]

  

A list of attributes that need to be returned along with each message.

The following lists the names and descriptions of the attributes that
can be returned:

=over

=item * C<All> - returns all values.

=item * C<ApproximateFirstReceiveTimestamp> - returns the time when the
message was first received from the queue (epoch time in milliseconds).

=item * C<ApproximateReceiveCount> - returns the number of times a
message has been received from the queue but not deleted.

=item * C<SenderId> - returns the AWS account number (or the IP
address, if anonymous access is allowed) of the sender.

=item * C<SentTimestamp> - returns the time when the message was sent
to the queue (epoch time in milliseconds).

=back










=head2 MaxNumberOfMessages => Int

  

The maximum number of messages to return. Amazon SQS never returns more
messages than this value but may return fewer. Values can be from 1 to
10. Default is 1.

All of the messages are not necessarily returned.










=head2 MessageAttributeNames => ArrayRef[Str]

  

The name of the message attribute, where I<N> is the index. The message
attribute name can contain the following characters: A-Z, a-z, 0-9,
underscore (_), hyphen (-), and period (.). The name must not start or
end with a period, and it should not have successive periods. The name
is case sensitive and must be unique among all attribute names for the
message. The name can be up to 256 characters long. The name cannot
start with "AWS." or "Amazon." (or any variations in casing), because
these prefixes are reserved for use by Amazon Web Services.

When using C<ReceiveMessage>, you can send a list of attribute names to
receive, or you can return all of the attributes by specifying "All" or
".*" in your request. You can also use "foo.*" to return all message
attributes starting with the "foo" prefix.










=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.










=head2 VisibilityTimeout => Int

  

The duration (in seconds) that the received messages are hidden from
subsequent retrieve requests after being retrieved by a
C<ReceiveMessage> request.










=head2 WaitTimeSeconds => Int

  

The duration (in seconds) for which the call will wait for a message to
arrive in the queue before returning. If a message is available, the
call will return sooner than WaitTimeSeconds.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ReceiveMessage in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

