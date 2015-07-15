
package Paws::CodeDeploy::StopDeploymentOutput {
  use Moose;
  has status => (is => 'ro', isa => 'Str');
  has statusMessage => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::StopDeploymentOutput

=head1 ATTRIBUTES

=head2 status => Str

  

The status of the stop deployment operation:

=over

=item * Pending: The stop operation is pending.

=item * Succeeded: The stop operation succeeded.

=back









=head2 statusMessage => Str

  

An accompanying status message.











=cut

1;