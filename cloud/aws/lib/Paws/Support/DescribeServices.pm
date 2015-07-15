
package Paws::Support::DescribeServices {
  use Moose;
  has language => (is => 'ro', isa => 'Str');
  has serviceCodeList => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeServices');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::DescribeServicesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeServices - Arguments for method DescribeServices on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeServices on the 
AWS Support service. Use the attributes of this class
as arguments to method DescribeServices.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeServices.

As an example:

  $service_obj->DescribeServices(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 language => Str

  

The ISO 639-1 code for the language in which AWS provides support. AWS
Support currently supports English ("en") and Japanese ("ja"). Language
parameters must be passed explicitly for operations that take them.










=head2 serviceCodeList => ArrayRef[Str]

  

A JSON-formatted list of service codes available for AWS services.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeServices in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

