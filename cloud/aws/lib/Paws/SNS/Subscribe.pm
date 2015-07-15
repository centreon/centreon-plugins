
package Paws::SNS::Subscribe {
  use Moose;
  has Endpoint => (is => 'ro', isa => 'Str');
  has Protocol => (is => 'ro', isa => 'Str', required => 1);
  has TopicArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Subscribe');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::SubscribeResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SubscribeResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::Subscribe - Arguments for method Subscribe on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method Subscribe on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method Subscribe.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Subscribe.

As an example:

  $service_obj->Subscribe(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Endpoint => Str

  

The endpoint that you want to receive notifications. Endpoints vary by
protocol:

=over

=item * For the C<http> protocol, the endpoint is an URL beginning with
"http://"

=item * For the C<https> protocol, the endpoint is a URL beginning with
"https://"

=item * For the C<email> protocol, the endpoint is an email address

=item * For the C<email-json> protocol, the endpoint is an email
address

=item * For the C<sms> protocol, the endpoint is a phone number of an
SMS-enabled device

=item * For the C<sqs> protocol, the endpoint is the ARN of an Amazon
SQS queue

=item * For the C<application> protocol, the endpoint is the
EndpointArn of a mobile app and device.

=back










=head2 B<REQUIRED> Protocol => Str

  

The protocol you want to use. Supported protocols include:

=over

=item * C<http> -- delivery of JSON-encoded message via HTTP POST

=item * C<https> -- delivery of JSON-encoded message via HTTPS POST

=item * C<email> -- delivery of message via SMTP

=item * C<email-json> -- delivery of JSON-encoded message via SMTP

=item * C<sms> -- delivery of message via SMS

=item * C<sqs> -- delivery of JSON-encoded message to an Amazon SQS
queue

=item * C<application> -- delivery of JSON-encoded message to an
EndpointArn for a mobile app and device.

=back










=head2 B<REQUIRED> TopicArn => Str

  

The ARN of the topic you want to subscribe to.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Subscribe in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

