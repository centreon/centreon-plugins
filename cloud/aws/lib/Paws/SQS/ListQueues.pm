
package Paws::SQS::ListQueues {
  use Moose;
  has QueueNamePrefix => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListQueues');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SQS::ListQueuesResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListQueuesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::ListQueues - Arguments for method ListQueues on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListQueues on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method ListQueues.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListQueues.

As an example:

  $service_obj->ListQueues(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 QueueNamePrefix => Str

  

A string to use for filtering the list results. Only those queues whose
name begins with the specified string are returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListQueues in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

