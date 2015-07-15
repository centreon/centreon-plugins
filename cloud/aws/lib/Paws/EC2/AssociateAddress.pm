
package Paws::EC2::AssociateAddress {
  use Moose;
  has AllocationId => (is => 'ro', isa => 'Str');
  has AllowReassociation => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'allowReassociation' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has InstanceId => (is => 'ro', isa => 'Str');
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'networkInterfaceId' );
  has PrivateIpAddress => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'privateIpAddress' );
  has PublicIp => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AssociateAddress');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::AssociateAddressResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::AssociateAddress - Arguments for method AssociateAddress on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method AssociateAddress on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method AssociateAddress.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AssociateAddress.

As an example:

  $service_obj->AssociateAddress(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllocationId => Str

  

[EC2-VPC] The allocation ID. This is required for EC2-VPC.










=head2 AllowReassociation => Bool

  

[EC2-VPC] Allows an Elastic IP address that is already associated with
an instance or network interface to be re-associated with the specified
instance or network interface. Otherwise, the operation fails.

Default: C<false>










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 InstanceId => Str

  

The ID of the instance. This is required for EC2-Classic. For EC2-VPC,
you can specify either the instance ID or the network interface ID, but
not both. The operation fails if you specify an instance ID unless
exactly one network interface is attached.










=head2 NetworkInterfaceId => Str

  

[EC2-VPC] The ID of the network interface. If the instance has more
than one network interface, you must specify a network interface ID.










=head2 PrivateIpAddress => Str

  

[EC2-VPC] The primary or secondary private IP address to associate with
the Elastic IP address. If no private IP address is specified, the
Elastic IP address is associated with the primary private IP address.










=head2 PublicIp => Str

  

The Elastic IP address. This is required for EC2-Classic.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AssociateAddress in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

