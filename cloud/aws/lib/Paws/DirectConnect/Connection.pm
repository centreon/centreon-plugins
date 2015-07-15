
package Paws::DirectConnect::Connection {
  use Moose;
  has bandwidth => (is => 'ro', isa => 'Str');
  has connectionId => (is => 'ro', isa => 'Str');
  has connectionName => (is => 'ro', isa => 'Str');
  has connectionState => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Str');
  has ownerAccount => (is => 'ro', isa => 'Str');
  has partnerName => (is => 'ro', isa => 'Str');
  has region => (is => 'ro', isa => 'Str');
  has vlan => (is => 'ro', isa => 'Int');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::Connection

=head1 ATTRIBUTES

=head2 bandwidth => Str

  

Bandwidth of the connection.

Example: 1Gbps (for regular connections), or 500Mbps (for hosted
connections)

Default: None









=head2 connectionId => Str

  
=head2 connectionName => Str

  
=head2 connectionState => Str

  
=head2 location => Str

  
=head2 ownerAccount => Str

  
=head2 partnerName => Str

  
=head2 region => Str

  
=head2 vlan => Int

  


=cut

1;