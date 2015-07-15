
package Paws::SNS::ConfirmSubscription {
  use Moose;
  has AuthenticateOnUnsubscribe => (is => 'ro', isa => 'Str');
  has Token => (is => 'ro', isa => 'Str', required => 1);
  has TopicArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ConfirmSubscription');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::ConfirmSubscriptionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ConfirmSubscriptionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ConfirmSubscription - Arguments for method ConfirmSubscription on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ConfirmSubscription on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method ConfirmSubscription.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ConfirmSubscription.

As an example:

  $service_obj->ConfirmSubscription(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AuthenticateOnUnsubscribe => Str

  

Disallows unauthenticated unsubscribes of the subscription. If the
value of this parameter is C<true> and the request has an AWS
signature, then only the topic owner and the subscription owner can
unsubscribe the endpoint. The unsubscribe action requires AWS
authentication.










=head2 B<REQUIRED> Token => Str

  

Short-lived token sent to an endpoint during the C<Subscribe> action.










=head2 B<REQUIRED> TopicArn => Str

  

The ARN of the topic for which you wish to confirm a subscription.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ConfirmSubscription in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

