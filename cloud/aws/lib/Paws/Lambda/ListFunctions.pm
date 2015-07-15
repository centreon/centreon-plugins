
package Paws::Lambda::ListFunctions {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Marker' );
  has MaxItems => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'MaxItems' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListFunctions');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/functions/');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::ListFunctionsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListFunctionsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::ListFunctions - Arguments for method ListFunctions on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListFunctions on the 
AWS Lambda service. Use the attributes of this class
as arguments to method ListFunctions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListFunctions.

As an example:

  $service_obj->ListFunctions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Marker => Str

  

Optional string. An opaque pagination token returned from a previous
C<ListFunctions> operation. If present, indicates where to continue the
listing.










=head2 MaxItems => Int

  

Optional integer. Specifies the maximum number of AWS Lambda functions
to return in response. This parameter value must be greater than 0.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListFunctions in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

