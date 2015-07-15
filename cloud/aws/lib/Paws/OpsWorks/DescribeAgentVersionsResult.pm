
package Paws::OpsWorks::DescribeAgentVersionsResult {
  use Moose;
  has AgentVersions => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::AgentVersion]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeAgentVersionsResult

=head1 ATTRIBUTES

=head2 AgentVersions => ArrayRef[Paws::OpsWorks::AgentVersion]

  

The agent versions for the specified stack or configuration manager.
Note that this value is the complete version number, not the
abbreviated number used by the console.











=cut

1;