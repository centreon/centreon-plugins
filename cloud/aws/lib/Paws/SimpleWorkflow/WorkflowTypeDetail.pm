
package Paws::SimpleWorkflow::WorkflowTypeDetail {
  use Moose;
  has configuration => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowTypeConfiguration', required => 1);
  has typeInfo => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowTypeInfo', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::WorkflowTypeDetail

=head1 ATTRIBUTES

=head2 B<REQUIRED> configuration => Paws::SimpleWorkflow::WorkflowTypeConfiguration

  

Configuration settings of the workflow type registered through
RegisterWorkflowType









=head2 B<REQUIRED> typeInfo => Paws::SimpleWorkflow::WorkflowTypeInfo

  

General information about the workflow type.

The status of the workflow type (returned in the WorkflowTypeInfo
structure) can be one of the following.

=over

=item * B<REGISTERED>: The type is registered and available. Workers
supporting this type should be running.

=item * B<DEPRECATED>: The type was deprecated using
DeprecateWorkflowType, but is still in use. You should keep workers
supporting this type running. You cannot create new workflow executions
of this type.

=back











=cut

1;