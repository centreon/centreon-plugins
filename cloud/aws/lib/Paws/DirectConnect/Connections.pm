
package Paws::DirectConnect::Connections {
  use Moose;
  has connections => (is => 'ro', isa => 'ArrayRef[Paws::DirectConnect::Connection]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::Connections

=head1 ATTRIBUTES

=head2 connections => ArrayRef[Paws::DirectConnect::Connection]

  

A list of connections.











=cut

1;