
package Paws::EC2::EnableVgwRoutePropagation {
  use Moose;
  has GatewayId => (is => 'ro', isa => 'Str', required => 1);
  has RouteTableId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'EnableVgwRoutePropagation');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::EnableVgwRoutePropagation - Arguments for method EnableVgwRoutePropagation on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method EnableVgwRoutePropagation on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method EnableVgwRoutePropagation.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to EnableVgwRoutePropagation.

As an example:

  $service_obj->EnableVgwRoutePropagation(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GatewayId => Str

  

The ID of the virtual private gateway.










=head2 B<REQUIRED> RouteTableId => Str

  

The ID of the route table.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method EnableVgwRoutePropagation in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

