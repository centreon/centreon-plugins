
package Paws::DirectConnect::Interconnect {
  use Moose;
  has bandwidth => (is => 'ro', isa => 'Str');
  has interconnectId => (is => 'ro', isa => 'Str');
  has interconnectName => (is => 'ro', isa => 'Str');
  has interconnectState => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Str');
  has region => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::Interconnect

=head1 ATTRIBUTES

=head2 bandwidth => Str

  
=head2 interconnectId => Str

  
=head2 interconnectName => Str

  
=head2 interconnectState => Str

  
=head2 location => Str

  
=head2 region => Str

  


=cut

1;