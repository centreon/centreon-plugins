
package Paws::SNS::SetPlatformApplicationAttributes {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::MapStringToString', required => 1);
  has PlatformApplicationArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetPlatformApplicationAttributes');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::SetPlatformApplicationAttributes - Arguments for method SetPlatformApplicationAttributes on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetPlatformApplicationAttributes on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method SetPlatformApplicationAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetPlatformApplicationAttributes.

As an example:

  $service_obj->SetPlatformApplicationAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Attributes => Paws::SNS::MapStringToString

  

A map of the platform application attributes. Attributes in this map
include the following:

=over

=item * C<PlatformCredential> -- The credential received from the
notification service. For APNS/APNS_SANDBOX, PlatformCredential is
"private key". For GCM, PlatformCredential is "API key". For ADM,
PlatformCredential is "client secret".

=item * C<PlatformPrincipal> -- The principal received from the
notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL
certificate". For GCM, PlatformPrincipal is not applicable. For ADM,
PlatformPrincipal is "client id".

=item * C<EventEndpointCreated> -- Topic ARN to which EndpointCreated
event notifications should be sent.

=item * C<EventEndpointDeleted> -- Topic ARN to which EndpointDeleted
event notifications should be sent.

=item * C<EventEndpointUpdated> -- Topic ARN to which EndpointUpdate
event notifications should be sent.

=item * C<EventDeliveryFailure> -- Topic ARN to which DeliveryFailure
event notifications should be sent upon Direct Publish delivery failure
(permanent) to one of the application's endpoints.

=back










=head2 B<REQUIRED> PlatformApplicationArn => Str

  

PlatformApplicationArn for SetPlatformApplicationAttributes action.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetPlatformApplicationAttributes in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

