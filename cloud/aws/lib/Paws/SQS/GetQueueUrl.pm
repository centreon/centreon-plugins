
package Paws::SQS::GetQueueUrl {
  use Moose;
  has QueueName => (is => 'ro', isa => 'Str', required => 1);
  has QueueOwnerAWSAccountId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetQueueUrl');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SQS::GetQueueUrlResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetQueueUrlResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::GetQueueUrl - Arguments for method GetQueueUrl on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetQueueUrl on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method GetQueueUrl.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetQueueUrl.

As an example:

  $service_obj->GetQueueUrl(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> QueueName => Str

  

The name of the queue whose URL must be fetched. Maximum 80 characters;
alphanumeric characters, hyphens (-), and underscores (_) are allowed.










=head2 QueueOwnerAWSAccountId => Str

  

The AWS account ID of the account that created the queue.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetQueueUrl in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

