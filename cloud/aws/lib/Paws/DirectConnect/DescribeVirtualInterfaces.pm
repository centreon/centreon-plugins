
package Paws::DirectConnect::DescribeVirtualInterfaces {
  use Moose;
  has connectionId => (is => 'ro', isa => 'Str');
  has virtualInterfaceId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeVirtualInterfaces');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::VirtualInterfaces');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::DescribeVirtualInterfaces - Arguments for method DescribeVirtualInterfaces on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeVirtualInterfaces on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method DescribeVirtualInterfaces.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeVirtualInterfaces.

As an example:

  $service_obj->DescribeVirtualInterfaces(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 connectionId => Str

  

=head2 virtualInterfaceId => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeVirtualInterfaces in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

