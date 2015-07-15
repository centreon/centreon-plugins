package Paws::DirectConnect {
  use Moose;
  sub service { 'directconnect' }
  sub version { '2012-10-25' }
  sub target_prefix { 'OvertureService' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub AllocateConnectionOnInterconnect {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::AllocateConnectionOnInterconnect', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AllocatePrivateVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::AllocatePrivateVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AllocatePublicVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::AllocatePublicVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ConfirmConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::ConfirmConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ConfirmPrivateVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::ConfirmPrivateVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ConfirmPublicVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::ConfirmPublicVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::CreateConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInterconnect {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::CreateInterconnect', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePrivateVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::CreatePrivateVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePublicVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::CreatePublicVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DeleteConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteInterconnect {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DeleteInterconnect', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVirtualInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DeleteVirtualInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConnections {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeConnections', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConnectionsOnInterconnect {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeConnectionsOnInterconnect', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInterconnects {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeInterconnects', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeLocations {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeLocations', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVirtualGateways {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeVirtualGateways', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVirtualInterfaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DirectConnect::DescribeVirtualInterfaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect - Perl Interface to AWS AWS Direct Connect

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('DirectConnect')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS Direct Connect makes it easy to establish a dedicated network
connection from your premises to Amazon Web Services (AWS). Using AWS
Direct Connect, you can establish private connectivity between AWS and
your data center, office, or colocation environment, which in many
cases can reduce your network costs, increase bandwidth throughput, and
provide a more consistent network experience than Internet-based
connections.

The AWS Direct Connect API Reference provides descriptions, syntax, and
usage examples for each of the actions and data types for AWS Direct
Connect. Use the following links to get started using the I<AWS Direct
Connect API Reference>:

=over

=item * Actions: An alphabetical list of all AWS Direct Connect
actions.

=item * Data Types: An alphabetical list of all AWS Direct Connect data
types.

=item * Common Query Parameters: Parameters that all Query actions can
use.

=item * Common Errors: Client and server errors that all actions can
return.

=back










=head1 METHODS

=head2 AllocateConnectionOnInterconnect(bandwidth => Str, connectionName => Str, interconnectId => Str, ownerAccount => Str, vlan => Int)

Each argument is described in detail in: L<Paws::DirectConnect::AllocateConnectionOnInterconnect>

Returns: a L<Paws::DirectConnect::Connection> instance

  

Creates a hosted connection on an interconnect.

Allocates a VLAN number and a specified amount of bandwidth for use by
a hosted connection on the given interconnect.











=head2 AllocatePrivateVirtualInterface(connectionId => Str, newPrivateVirtualInterfaceAllocation => Paws::DirectConnect::NewPrivateVirtualInterfaceAllocation, ownerAccount => Str)

Each argument is described in detail in: L<Paws::DirectConnect::AllocatePrivateVirtualInterface>

Returns: a L<Paws::DirectConnect::VirtualInterface> instance

  

Provisions a private virtual interface to be owned by a different
customer.

The owner of a connection calls this function to provision a private
virtual interface which will be owned by another AWS customer.

Virtual interfaces created using this function must be confirmed by the
virtual interface owner by calling ConfirmPrivateVirtualInterface.
Until this step has been completed, the virtual interface will be in
'Confirming' state, and will not be available for handling traffic.











=head2 AllocatePublicVirtualInterface(connectionId => Str, newPublicVirtualInterfaceAllocation => Paws::DirectConnect::NewPublicVirtualInterfaceAllocation, ownerAccount => Str)

Each argument is described in detail in: L<Paws::DirectConnect::AllocatePublicVirtualInterface>

Returns: a L<Paws::DirectConnect::VirtualInterface> instance

  

Provisions a public virtual interface to be owned by a different
customer.

The owner of a connection calls this function to provision a public
virtual interface which will be owned by another AWS customer.

Virtual interfaces created using this function must be confirmed by the
virtual interface owner by calling ConfirmPublicVirtualInterface. Until
this step has been completed, the virtual interface will be in
'Confirming' state, and will not be available for handling traffic.











=head2 ConfirmConnection(connectionId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::ConfirmConnection>

Returns: a L<Paws::DirectConnect::ConfirmConnectionResponse> instance

  

Confirm the creation of a hosted connection on an interconnect.

Upon creation, the hosted connection is initially in the 'Ordering'
state, and will remain in this state until the owner calls
ConfirmConnection to confirm creation of the hosted connection.











=head2 ConfirmPrivateVirtualInterface(virtualGatewayId => Str, virtualInterfaceId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::ConfirmPrivateVirtualInterface>

Returns: a L<Paws::DirectConnect::ConfirmPrivateVirtualInterfaceResponse> instance

  

Accept ownership of a private virtual interface created by another
customer.

After the virtual interface owner calls this function, the virtual
interface will be created and attached to the given virtual private
gateway, and will be available for handling traffic.











=head2 ConfirmPublicVirtualInterface(virtualInterfaceId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::ConfirmPublicVirtualInterface>

Returns: a L<Paws::DirectConnect::ConfirmPublicVirtualInterfaceResponse> instance

  

Accept ownership of a public virtual interface created by another
customer.

After the virtual interface owner calls this function, the specified
virtual interface will be created and made available for handling
traffic.











=head2 CreateConnection(bandwidth => Str, connectionName => Str, location => Str)

Each argument is described in detail in: L<Paws::DirectConnect::CreateConnection>

Returns: a L<Paws::DirectConnect::Connection> instance

  

Creates a new connection between the customer network and a specific
AWS Direct Connect location.

A connection links your internal network to an AWS Direct Connect
location over a standard 1 gigabit or 10 gigabit Ethernet fiber-optic
cable. One end of the cable is connected to your router, the other to
an AWS Direct Connect router. An AWS Direct Connect location provides
access to Amazon Web Services in the region it is associated with. You
can establish connections with AWS Direct Connect locations in multiple
regions, but a connection in one region does not provide connectivity
to other regions.











=head2 CreateInterconnect(bandwidth => Str, interconnectName => Str, location => Str)

Each argument is described in detail in: L<Paws::DirectConnect::CreateInterconnect>

Returns: a L<Paws::DirectConnect::Interconnect> instance

  

Creates a new interconnect between a AWS Direct Connect partner's
network and a specific AWS Direct Connect location.

An interconnect is a connection which is capable of hosting other
connections. The AWS Direct Connect partner can use an interconnect to
provide sub-1Gbps AWS Direct Connect service to tier 2 customers who do
not have their own connections. Like a standard connection, an
interconnect links the AWS Direct Connect partner's network to an AWS
Direct Connect location over a standard 1 Gbps or 10 Gbps Ethernet
fiber-optic cable. One end is connected to the partner's router, the
other to an AWS Direct Connect router.

For each end customer, the AWS Direct Connect partner provisions a
connection on their interconnect by calling
AllocateConnectionOnInterconnect. The end customer can then connect to
AWS resources by creating a virtual interface on their connection,
using the VLAN assigned to them by the AWS Direct Connect partner.











=head2 CreatePrivateVirtualInterface(connectionId => Str, newPrivateVirtualInterface => Paws::DirectConnect::NewPrivateVirtualInterface)

Each argument is described in detail in: L<Paws::DirectConnect::CreatePrivateVirtualInterface>

Returns: a L<Paws::DirectConnect::VirtualInterface> instance

  

Creates a new private virtual interface. A virtual interface is the
VLAN that transports AWS Direct Connect traffic. A private virtual
interface supports sending traffic to a single virtual private cloud
(VPC).











=head2 CreatePublicVirtualInterface(connectionId => Str, newPublicVirtualInterface => Paws::DirectConnect::NewPublicVirtualInterface)

Each argument is described in detail in: L<Paws::DirectConnect::CreatePublicVirtualInterface>

Returns: a L<Paws::DirectConnect::VirtualInterface> instance

  

Creates a new public virtual interface. A virtual interface is the VLAN
that transports AWS Direct Connect traffic. A public virtual interface
supports sending traffic to public services of AWS such as Amazon
Simple Storage Service (Amazon S3).











=head2 DeleteConnection(connectionId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::DeleteConnection>

Returns: a L<Paws::DirectConnect::Connection> instance

  

Deletes the connection.

Deleting a connection only stops the AWS Direct Connect port hour and
data transfer charges. You need to cancel separately with the providers
any services or charges for cross-connects or network circuits that
connect you to the AWS Direct Connect location.











=head2 DeleteInterconnect(interconnectId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::DeleteInterconnect>

Returns: a L<Paws::DirectConnect::DeleteInterconnectResponse> instance

  

Deletes the specified interconnect.











=head2 DeleteVirtualInterface(virtualInterfaceId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::DeleteVirtualInterface>

Returns: a L<Paws::DirectConnect::DeleteVirtualInterfaceResponse> instance

  

Deletes a virtual interface.











=head2 DescribeConnections([connectionId => Str])

Each argument is described in detail in: L<Paws::DirectConnect::DescribeConnections>

Returns: a L<Paws::DirectConnect::Connections> instance

  

Displays all connections in this region.

If a connection ID is provided, the call returns only that particular
connection.











=head2 DescribeConnectionsOnInterconnect(interconnectId => Str)

Each argument is described in detail in: L<Paws::DirectConnect::DescribeConnectionsOnInterconnect>

Returns: a L<Paws::DirectConnect::Connections> instance

  

Return a list of connections that have been provisioned on the given
interconnect.











=head2 DescribeInterconnects([interconnectId => Str])

Each argument is described in detail in: L<Paws::DirectConnect::DescribeInterconnects>

Returns: a L<Paws::DirectConnect::Interconnects> instance

  

Returns a list of interconnects owned by the AWS account.

If an interconnect ID is provided, it will only return this particular
interconnect.











=head2 DescribeLocations( => )

Each argument is described in detail in: L<Paws::DirectConnect::DescribeLocations>

Returns: a L<Paws::DirectConnect::Locations> instance

  

Returns the list of AWS Direct Connect locations in the current AWS
region. These are the locations that may be selected when calling
CreateConnection or CreateInterconnect.











=head2 DescribeVirtualGateways( => )

Each argument is described in detail in: L<Paws::DirectConnect::DescribeVirtualGateways>

Returns: a L<Paws::DirectConnect::VirtualGateways> instance

  

Returns a list of virtual private gateways owned by the AWS account.

You can create one or more AWS Direct Connect private virtual
interfaces linking to a virtual private gateway. A virtual private
gateway can be managed via Amazon Virtual Private Cloud (VPC) console
or the EC2 CreateVpnGateway action.











=head2 DescribeVirtualInterfaces([connectionId => Str, virtualInterfaceId => Str])

Each argument is described in detail in: L<Paws::DirectConnect::DescribeVirtualInterfaces>

Returns: a L<Paws::DirectConnect::VirtualInterfaces> instance

  

Displays all virtual interfaces for an AWS account. Virtual interfaces
deleted fewer than 15 minutes before DescribeVirtualInterfaces is
called are also returned. If a connection ID is included then only
virtual interfaces associated with this connection will be returned. If
a virtual interface ID is included then only a single virtual interface
will be returned.

A virtual interface (VLAN) transmits the traffic between the AWS Direct
Connect location and the customer.

If a connection ID is provided, only virtual interfaces provisioned on
the specified connection will be returned. If a virtual interface ID is
provided, only this particular virtual interface will be returned.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

