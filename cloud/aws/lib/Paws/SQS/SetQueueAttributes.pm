
package Paws::SQS::SetQueueAttributes {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SQS::QueueAttributeMap', traits => ['NameInRequest'], request_name => 'Attribute' , required => 1);
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetQueueAttributes');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::SetQueueAttributes - Arguments for method SetQueueAttributes on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetQueueAttributes on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method SetQueueAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetQueueAttributes.

As an example:

  $service_obj->SetQueueAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Attributes => Paws::SQS::QueueAttributeMap

  

A map of attributes to set.

The following lists the names, descriptions, and values of the special
request parameters the C<SetQueueAttributes> action uses:

=over

=item * C<DelaySeconds> - The time in seconds that the delivery of all
messages in the queue will be delayed. An integer from 0 to 900 (15
minutes). The default for this attribute is 0 (zero).

=item * C<MaximumMessageSize> - The limit of how many bytes a message
can contain before Amazon SQS rejects it. An integer from 1024 bytes (1
KiB) up to 262144 bytes (256 KiB). The default for this attribute is
262144 (256 KiB).

=item * C<MessageRetentionPeriod> - The number of seconds Amazon SQS
retains a message. Integer representing seconds, from 60 (1 minute) to
1209600 (14 days). The default for this attribute is 345600 (4 days).

=item * C<Policy> - The queue's policy. A valid AWS policy. For more
information about policy structure, see Overview of AWS IAM Policies in
the I<Amazon IAM User Guide>.

=item * C<ReceiveMessageWaitTimeSeconds> - The time for which a
ReceiveMessage call will wait for a message to arrive. An integer from
0 to 20 (seconds). The default for this attribute is 0.

=item * C<VisibilityTimeout> - The visibility timeout for the queue. An
integer from 0 to 43200 (12 hours). The default for this attribute is
30. For more information about visibility timeout, see Visibility
Timeout in the I<Amazon SQS Developer Guide>.

=item * C<RedrivePolicy> - The parameters for dead letter queue
functionality of the source queue. For more information about
RedrivePolicy and dead letter queues, see Using Amazon SQS Dead Letter
Queues in the I<Amazon SQS Developer Guide>.

=back










=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetQueueAttributes in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

