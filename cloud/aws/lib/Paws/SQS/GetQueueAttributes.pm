
package Paws::SQS::GetQueueAttributes {
  use Moose;
  has AttributeNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetQueueAttributes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SQS::GetQueueAttributesResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetQueueAttributesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::GetQueueAttributes - Arguments for method GetQueueAttributes on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetQueueAttributes on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method GetQueueAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetQueueAttributes.

As an example:

  $service_obj->GetQueueAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AttributeNames => ArrayRef[Str]

  

A list of attributes to retrieve information for.










=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetQueueAttributes in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

