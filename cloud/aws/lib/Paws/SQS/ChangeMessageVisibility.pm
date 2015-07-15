
package Paws::SQS::ChangeMessageVisibility {
  use Moose;
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);
  has ReceiptHandle => (is => 'ro', isa => 'Str', required => 1);
  has VisibilityTimeout => (is => 'ro', isa => 'Int', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ChangeMessageVisibility');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::ChangeMessageVisibility - Arguments for method ChangeMessageVisibility on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ChangeMessageVisibility on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method ChangeMessageVisibility.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ChangeMessageVisibility.

As an example:

  $service_obj->ChangeMessageVisibility(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.










=head2 B<REQUIRED> ReceiptHandle => Str

  

The receipt handle associated with the message whose visibility timeout
should be changed. This parameter is returned by the ReceiveMessage
action.










=head2 B<REQUIRED> VisibilityTimeout => Int

  

The new value (in seconds - from 0 to 43200 - maximum 12 hours) for the
message's visibility timeout.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ChangeMessageVisibility in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

