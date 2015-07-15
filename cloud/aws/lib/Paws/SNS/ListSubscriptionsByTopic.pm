
package Paws::SNS::ListSubscriptionsByTopic {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has TopicArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListSubscriptionsByTopic');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::ListSubscriptionsByTopicResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListSubscriptionsByTopicResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ListSubscriptionsByTopic - Arguments for method ListSubscriptionsByTopic on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListSubscriptionsByTopic on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method ListSubscriptionsByTopic.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListSubscriptionsByTopic.

As an example:

  $service_obj->ListSubscriptionsByTopic(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 NextToken => Str

  

Token returned by the previous C<ListSubscriptionsByTopic> request.










=head2 B<REQUIRED> TopicArn => Str

  

The ARN of the topic for which you wish to find subscriptions.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListSubscriptionsByTopic in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

