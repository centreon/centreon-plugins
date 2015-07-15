
package Paws::SNS::CreatePlatformEndpoint {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::MapStringToString');
  has CustomUserData => (is => 'ro', isa => 'Str');
  has PlatformApplicationArn => (is => 'ro', isa => 'Str', required => 1);
  has Token => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreatePlatformEndpoint');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::CreateEndpointResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreatePlatformEndpointResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::CreatePlatformEndpoint - Arguments for method CreatePlatformEndpoint on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreatePlatformEndpoint on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method CreatePlatformEndpoint.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreatePlatformEndpoint.

As an example:

  $service_obj->CreatePlatformEndpoint(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attributes => Paws::SNS::MapStringToString

  

For a list of attributes, see SetEndpointAttributes.










=head2 CustomUserData => Str

  

Arbitrary user data to associate with the endpoint. Amazon SNS does not
use this data. The data must be in UTF-8 format and less than 2KB.










=head2 B<REQUIRED> PlatformApplicationArn => Str

  

PlatformApplicationArn returned from CreatePlatformApplication is used
to create a an endpoint.










=head2 B<REQUIRED> Token => Str

  

Unique identifier created by the notification service for an app on a
device. The specific name for Token will vary, depending on which
notification service is being used. For example, when using APNS as the
notification service, you need the device token. Alternatively, when
using GCM or ADM, the device token equivalent is called the
registration ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreatePlatformEndpoint in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

