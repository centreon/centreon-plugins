
package Paws::SNS::SetSubscriptionAttributes {
  use Moose;
  has AttributeName => (is => 'ro', isa => 'Str', required => 1);
  has AttributeValue => (is => 'ro', isa => 'Str');
  has SubscriptionArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetSubscriptionAttributes');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::SetSubscriptionAttributes - Arguments for method SetSubscriptionAttributes on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetSubscriptionAttributes on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method SetSubscriptionAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetSubscriptionAttributes.

As an example:

  $service_obj->SetSubscriptionAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AttributeName => Str

  

The name of the attribute you want to set. Only a subset of the
subscriptions attributes are mutable.

Valid values: C<DeliveryPolicy> | C<RawMessageDelivery>










=head2 AttributeValue => Str

  

The new value for the attribute in JSON format.










=head2 B<REQUIRED> SubscriptionArn => Str

  

The ARN of the subscription to modify.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetSubscriptionAttributes in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

