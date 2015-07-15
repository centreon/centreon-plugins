
package Paws::DirectConnect::DescribeConnectionsOnInterconnect {
  use Moose;
  has interconnectId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeConnectionsOnInterconnect');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::Connections');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::DescribeConnectionsOnInterconnect - Arguments for method DescribeConnectionsOnInterconnect on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeConnectionsOnInterconnect on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method DescribeConnectionsOnInterconnect.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeConnectionsOnInterconnect.

As an example:

  $service_obj->DescribeConnectionsOnInterconnect(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> interconnectId => Str

  

ID of the interconnect on which a list of connection is provisioned.

Example: dxcon-abc123

Default: None












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeConnectionsOnInterconnect in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

