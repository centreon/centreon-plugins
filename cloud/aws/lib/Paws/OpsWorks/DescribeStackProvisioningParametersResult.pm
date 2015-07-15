
package Paws::OpsWorks::DescribeStackProvisioningParametersResult {
  use Moose;
  has AgentInstallerUrl => (is => 'ro', isa => 'Str');
  has Parameters => (is => 'ro', isa => 'Paws::OpsWorks::Parameters');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeStackProvisioningParametersResult

=head1 ATTRIBUTES

=head2 AgentInstallerUrl => Str

  

The AWS OpsWorks agent installer's URL.









=head2 Parameters => Paws::OpsWorks::Parameters

  

An embedded object that contains the provisioning parameters.











=cut

1;