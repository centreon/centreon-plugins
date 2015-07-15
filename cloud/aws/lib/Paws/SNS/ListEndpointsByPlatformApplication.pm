
package Paws::SNS::ListEndpointsByPlatformApplication {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has PlatformApplicationArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListEndpointsByPlatformApplication');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::ListEndpointsByPlatformApplicationResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListEndpointsByPlatformApplicationResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ListEndpointsByPlatformApplication - Arguments for method ListEndpointsByPlatformApplication on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListEndpointsByPlatformApplication on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method ListEndpointsByPlatformApplication.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListEndpointsByPlatformApplication.

As an example:

  $service_obj->ListEndpointsByPlatformApplication(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 NextToken => Str

  

NextToken string is used when calling
ListEndpointsByPlatformApplication action to retrieve additional
records that are available after the first page results.










=head2 B<REQUIRED> PlatformApplicationArn => Str

  

PlatformApplicationArn for ListEndpointsByPlatformApplicationInput
action.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListEndpointsByPlatformApplication in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

