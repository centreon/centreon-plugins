
package Paws::EC2::UnassignPrivateIpAddresses {
  use Moose;
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'networkInterfaceId' , required => 1);
  has PrivateIpAddresses => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'privateIpAddress' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UnassignPrivateIpAddresses');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::UnassignPrivateIpAddresses - Arguments for method UnassignPrivateIpAddresses on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method UnassignPrivateIpAddresses on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method UnassignPrivateIpAddresses.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UnassignPrivateIpAddresses.

As an example:

  $service_obj->UnassignPrivateIpAddresses(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> NetworkInterfaceId => Str

  

The ID of the network interface.










=head2 B<REQUIRED> PrivateIpAddresses => ArrayRef[Str]

  

The secondary private IP addresses to unassign from the network
interface. You can specify this option multiple times to unassign more
than one IP address.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UnassignPrivateIpAddresses in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

