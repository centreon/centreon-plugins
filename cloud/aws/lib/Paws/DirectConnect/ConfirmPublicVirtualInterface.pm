
package Paws::DirectConnect::ConfirmPublicVirtualInterface {
  use Moose;
  has virtualInterfaceId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ConfirmPublicVirtualInterface');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::ConfirmPublicVirtualInterfaceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::ConfirmPublicVirtualInterface - Arguments for method ConfirmPublicVirtualInterface on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method ConfirmPublicVirtualInterface on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method ConfirmPublicVirtualInterface.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ConfirmPublicVirtualInterface.

As an example:

  $service_obj->ConfirmPublicVirtualInterface(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> virtualInterfaceId => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ConfirmPublicVirtualInterface in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

