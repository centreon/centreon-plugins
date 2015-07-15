
package Paws::DirectConnect::AllocateConnectionOnInterconnect {
  use Moose;
  has bandwidth => (is => 'ro', isa => 'Str', required => 1);
  has connectionName => (is => 'ro', isa => 'Str', required => 1);
  has interconnectId => (is => 'ro', isa => 'Str', required => 1);
  has ownerAccount => (is => 'ro', isa => 'Str', required => 1);
  has vlan => (is => 'ro', isa => 'Int', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AllocateConnectionOnInterconnect');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DirectConnect::Connection');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::AllocateConnectionOnInterconnect - Arguments for method AllocateConnectionOnInterconnect on Paws::DirectConnect

=head1 DESCRIPTION

This class represents the parameters used for calling the method AllocateConnectionOnInterconnect on the 
AWS Direct Connect service. Use the attributes of this class
as arguments to method AllocateConnectionOnInterconnect.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AllocateConnectionOnInterconnect.

As an example:

  $service_obj->AllocateConnectionOnInterconnect(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> bandwidth => Str

  

Bandwidth of the connection.

Example: "I<500Mbps>"

Default: None










=head2 B<REQUIRED> connectionName => Str

  

Name of the provisioned connection.

Example: "I<500M Connection to AWS>"

Default: None










=head2 B<REQUIRED> interconnectId => Str

  

ID of the interconnect on which the connection will be provisioned.

Example: dxcon-456abc78

Default: None










=head2 B<REQUIRED> ownerAccount => Str

  

Numeric account Id of the customer for whom the connection will be
provisioned.

Example: 123443215678

Default: None










=head2 B<REQUIRED> vlan => Int

  

The dedicated VLAN provisioned to the connection.

Example: 101

Default: None












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AllocateConnectionOnInterconnect in L<Paws::DirectConnect>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

