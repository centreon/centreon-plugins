
package Paws::OpsWorks::DescribeCommandsResult {
  use Moose;
  has Commands => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Command]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeCommandsResult

=head1 ATTRIBUTES

=head2 Commands => ArrayRef[Paws::OpsWorks::Command]

  

An array of C<Command> objects that describe each of the specified
commands.











=cut

1;