
package Paws::CognitoSync::RegisterDevice {
  use Moose;
  has IdentityId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityId' , required => 1);
  has IdentityPoolId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityPoolId' , required => 1);
  has Platform => (is => 'ro', isa => 'Str', required => 1);
  has Token => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RegisterDevice');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/identitypools/{IdentityPoolId}/identity/{IdentityId}/device');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoSync::RegisterDeviceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RegisterDeviceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::RegisterDevice - Arguments for method RegisterDevice on Paws::CognitoSync

=head1 DESCRIPTION

This class represents the parameters used for calling the method RegisterDevice on the 
Amazon Cognito Sync service. Use the attributes of this class
as arguments to method RegisterDevice.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RegisterDevice.

As an example:

  $service_obj->RegisterDevice(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> IdentityId => Str

  

The unique ID for this identity.










=head2 B<REQUIRED> IdentityPoolId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. Here, the ID of the pool that the identity belongs to.










=head2 B<REQUIRED> Platform => Str

  

The SNS platform type (e.g. GCM, SDM, APNS, APNS_SANDBOX).










=head2 B<REQUIRED> Token => Str

  

The push token.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RegisterDevice in L<Paws::CognitoSync>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

