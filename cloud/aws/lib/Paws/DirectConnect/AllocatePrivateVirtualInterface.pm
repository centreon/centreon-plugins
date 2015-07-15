
package Paws::DirectConnect::AllocatePrivateVirtualInterface {
  use Moose;
  has connectionId => (is => 'ro', isa => 'Str', required => 1);
  has newPrivateVirtualInterfaceAllocation => (is => 'ro', isa => 'Paws::DirectConnect::NewPrivateVirtualInterfaceAllocation', required => 1);
  has ownerAccount => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AllocatePrivateVirtualInterface');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::VirtualInterface');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::AllocatePrivateVirtualInterface - Arguments for method AllocatePrivateVirtualInterface on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method AllocatePrivateVirtualInterface on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method AllocatePrivateVirtualInterface.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AllocatePrivateVirtualInterface.

As an example:

  $service_obj->AllocatePrivateVirtualInterface(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> connectionId => Str

  

The connection ID on which the private virtual interface is
provisioned.

Default: None










=head2 B<REQUIRED> newPrivateVirtualInterfaceAllocation => Paws::DirectConnect::NewPrivateVirtualInterfaceAllocation

  

Detailed information for the private virtual interface to be
provisioned.

Default: None










=head2 B<REQUIRED> ownerAccount => Str

  

The AWS account that will own the new private virtual interface.

Default: None












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AllocatePrivateVirtualInterface in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

