
package Paws::CodeDeploy::BatchGetApplicationsOutput {
  use Moose;
  has applicationsInfo => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::ApplicationInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::BatchGetApplicationsOutput

=head1 ATTRIBUTES

=head2 applicationsInfo => ArrayRef[Paws::CodeDeploy::ApplicationInfo]

  

Information about the applications.











=cut

1;