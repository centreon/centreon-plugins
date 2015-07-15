
package Paws::SimpleWorkflow::ActivityTypeDetail {
  use Moose;
  has configuration => (is => 'ro', isa => 'Paws::SimpleWorkflow::ActivityTypeConfiguration', required => 1);
  has typeInfo => (is => 'ro', isa => 'Paws::SimpleWorkflow::ActivityTypeInfo', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::ActivityTypeDetail

=head1 ATTRIBUTES

=head2 B<REQUIRED> configuration => Paws::SimpleWorkflow::ActivityTypeConfiguration

  

The configuration settings registered with the activity type.









=head2 B<REQUIRED> typeInfo => Paws::SimpleWorkflow::ActivityTypeInfo

  

General information about the activity type.

The status of activity type (returned in the ActivityTypeInfo
structure) can be one of the following.

=over

=item * B<REGISTERED>: The type is registered and available. Workers
supporting this type should be running.

=item * B<DEPRECATED>: The type was deprecated using
DeprecateActivityType, but is still in use. You should keep workers
supporting this type running. You cannot create new tasks of this type.

=back











=cut

1;