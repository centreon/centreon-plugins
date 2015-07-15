
package Paws::Lambda::GetEventSourceMapping {
  use Moose;
  has UUID => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'UUID' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetEventSourceMapping');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/event-source-mappings/{UUID}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::EventSourceMappingConfiguration');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetEventSourceMappingResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::GetEventSourceMapping - Arguments for method GetEventSourceMapping on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetEventSourceMapping on the 
AWS Lambda service. Use the attributes of this class
as arguments to method GetEventSourceMapping.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetEventSourceMapping.

As an example:

  $service_obj->GetEventSourceMapping(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> UUID => Str

  

The AWS Lambda assigned ID of the event source mapping.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetEventSourceMapping in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

