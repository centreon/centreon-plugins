
package Paws::SQS::SendMessage {
  use Moose;
  has DelaySeconds => (is => 'ro', isa => 'Int');
  has MessageAttributes => (is => 'ro', isa => 'Paws::SQS::MessageAttributeMap', traits => ['NameInRequest'], request_name => 'MessageAttribute' );
  has MessageBody => (is => 'ro', isa => 'Str', required => 1);
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SendMessage');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SQS::SendMessageResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SendMessageResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::SendMessage - Arguments for method SendMessage on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method SendMessage on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method SendMessage.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SendMessage.

As an example:

  $service_obj->SendMessage(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DelaySeconds => Int

  

The number of seconds (0 to 900 - 15 minutes) to delay a specific
message. Messages with a positive C<DelaySeconds> value become
available for processing after the delay time is finished. If you don't
specify a value, the default value for the queue applies.










=head2 MessageAttributes => Paws::SQS::MessageAttributeMap

  

Each message attribute consists of a Name, Type, and Value. For more
information, see Message Attribute Items.










=head2 B<REQUIRED> MessageBody => Str

  

The message to send. String maximum 256 KB in size. For a list of
allowed characters, see the preceding important note.










=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SendMessage in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

