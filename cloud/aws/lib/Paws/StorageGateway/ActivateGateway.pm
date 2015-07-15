
package Paws::StorageGateway::ActivateGateway {
  use Moose;
  has ActivationKey => (is => 'ro', isa => 'Str', required => 1);
  has GatewayName => (is => 'ro', isa => 'Str', required => 1);
  has GatewayRegion => (is => 'ro', isa => 'Str', required => 1);
  has GatewayTimezone => (is => 'ro', isa => 'Str', required => 1);
  has GatewayType => (is => 'ro', isa => 'Str');
  has MediumChangerType => (is => 'ro', isa => 'Str');
  has TapeDriveType => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ActivateGateway');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::ActivateGatewayOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ActivateGateway - Arguments for method ActivateGateway on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method ActivateGateway on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method ActivateGateway.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ActivateGateway.

As an example:

  $service_obj->ActivateGateway(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ActivationKey => Str

  

Your gateway activation key. You can obtain the activation key by
sending an HTTP GET request with redirects enabled to the gateway IP
address (port 80). The redirect URL returned in the response provides
you the activation key for your gateway in the query string parameter
C<activationKey>. It may also include other activation-related
parameters, however, these are merely defaults -- the arguments you
pass to the C<ActivateGateway> API call determine the actual
configuration of your gateway.










=head2 B<REQUIRED> GatewayName => Str

  

=head2 B<REQUIRED> GatewayRegion => Str

  

One of the values that indicates the region where you want to store the
snapshot backups. The gateway region specified must be the same region
as the region in your C<Host> header in the request. For more
information about available regions and endpoints for AWS Storage
Gateway, see Regions and Endpoints in the I<Amazon Web Services
Glossary>.

I<Valid Values>: "us-east-1", "us-west-1", "us-west-2", "eu-west-1",
"eu-central-1", "ap-northeast-1", "ap-southeast-1", "ap-southeast-2",
"sa-east-1"










=head2 B<REQUIRED> GatewayTimezone => Str

  

One of the values that indicates the time zone you want to set for the
gateway. The time zone is used, for example, for scheduling snapshots
and your gateway's maintenance schedule.










=head2 GatewayType => Str

  

One of the values that defines the type of gateway to activate. The
type specified is critical to all later functions of the gateway and
cannot be changed after activation. The default value is C<STORED>.










=head2 MediumChangerType => Str

  

The value that indicates the type of medium changer to use for
gateway-VTL. This field is optional.

I<Valid Values>: "STK-L700", "AWS-Gateway-VTL"










=head2 TapeDriveType => Str

  

The value that indicates the type of tape drive to use for gateway-VTL.
This field is optional.

I<Valid Values>: "IBM-ULT3580-TD5"












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ActivateGateway in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

