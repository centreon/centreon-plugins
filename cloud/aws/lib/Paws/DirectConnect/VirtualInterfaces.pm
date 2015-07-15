
package Paws::DirectConnect::VirtualInterfaces {
  use Moose;
  has virtualInterfaces => (is => 'ro', isa => 'ArrayRef[Paws::DirectConnect::VirtualInterface]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::VirtualInterfaces

=head1 ATTRIBUTES

=head2 virtualInterfaces => ArrayRef[Paws::DirectConnect::VirtualInterface]

  

A list of virtual interfaces.











=cut

1;