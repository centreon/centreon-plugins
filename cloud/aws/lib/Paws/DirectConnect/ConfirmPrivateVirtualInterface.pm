
package Paws::DirectConnect::ConfirmPrivateVirtualInterface {
  use Moose;
  has virtualGatewayId => (is => 'ro', isa => 'Str', required => 1);
  has virtualInterfaceId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ConfirmPrivateVirtualInterface');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::ConfirmPrivateVirtualInterfaceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::ConfirmPrivateVirtualInterface - Arguments for method ConfirmPrivateVirtualInterface on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method ConfirmPrivateVirtualInterface on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method ConfirmPrivateVirtualInterface.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ConfirmPrivateVirtualInterface.

As an example:

  $service_obj->ConfirmPrivateVirtualInterface(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> virtualGatewayId => Str

  

ID of the virtual private gateway that will be attached to the virtual
interface.

A virtual private gateway can be managed via the Amazon Virtual Private
Cloud (VPC) console or the EC2 CreateVpnGateway action.

Default: None










=head2 B<REQUIRED> virtualInterfaceId => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ConfirmPrivateVirtualInterface in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

