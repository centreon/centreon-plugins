
package Paws::EC2::CreateNetworkInterface {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'description' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Groups => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SecurityGroupId' );
  has PrivateIpAddress => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'privateIpAddress' );
  has PrivateIpAddresses => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PrivateIpAddressSpecification]', traits => ['NameInRequest'], request_name => 'privateIpAddresses' );
  has SecondaryPrivateIpAddressCount => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'secondaryPrivateIpAddressCount' );
  has SubnetId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'subnetId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateNetworkInterface');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateNetworkInterfaceResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateNetworkInterface - Arguments for method CreateNetworkInterface on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateNetworkInterface on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateNetworkInterface.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateNetworkInterface.

As an example:

  $service_obj->CreateNetworkInterface(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

A description for the network interface.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Groups => ArrayRef[Str]

  

The IDs of one or more security groups.










=head2 PrivateIpAddress => Str

  

The primary private IP address of the network interface. If you don't
specify an IP address, Amazon EC2 selects one for you from the subnet
range. If you specify an IP address, you cannot indicate any IP
addresses specified in C<privateIpAddresses> as primary (only one IP
address can be designated as primary).










=head2 PrivateIpAddresses => ArrayRef[Paws::EC2::PrivateIpAddressSpecification]

  

One or more private IP addresses.










=head2 SecondaryPrivateIpAddressCount => Int

  

The number of secondary private IP addresses to assign to a network
interface. When you specify a number of secondary IP addresses, Amazon
EC2 selects these IP addresses within the subnet range. You can't
specify this option and specify more than one private IP address using
C<privateIpAddresses>.

The number of IP addresses you can assign to a network interface varies
by instance type. For more information, see Private IP Addresses Per
ENI Per Instance Type in the I<Amazon Elastic Compute Cloud User
Guide>.










=head2 B<REQUIRED> SubnetId => Str

  

The ID of the subnet to associate with the network interface.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateNetworkInterface in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

