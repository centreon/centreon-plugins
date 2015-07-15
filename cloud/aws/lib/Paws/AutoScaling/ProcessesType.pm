
package Paws::AutoScaling::ProcessesType {
  use Moose;
  has Processes => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::ProcessType]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::ProcessesType

=head1 ATTRIBUTES

=head2 Processes => ArrayRef[Paws::AutoScaling::ProcessType]

  

The names of the process types.











=cut

