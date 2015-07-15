
package Paws::RedShift::CopyClusterSnapshot {
  use Moose;
  has SourceSnapshotClusterIdentifier => (is => 'ro', isa => 'Str');
  has SourceSnapshotIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has TargetSnapshotIdentifier => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CopyClusterSnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::CopyClusterSnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CopyClusterSnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CopyClusterSnapshot - Arguments for method CopyClusterSnapshot on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CopyClusterSnapshot on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CopyClusterSnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CopyClusterSnapshot.

As an example:

  $service_obj->CopyClusterSnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 SourceSnapshotClusterIdentifier => Str

  

The identifier of the cluster the source snapshot was created from.
This parameter is required if your IAM user has a policy containing a
snapshot resource element that specifies anything other than * for the
cluster name.

Constraints:

=over

=item * Must be the identifier for a valid cluster.

=back










=head2 B<REQUIRED> SourceSnapshotIdentifier => Str

  

The identifier for the source snapshot.

Constraints:

=over

=item * Must be the identifier for a valid automated snapshot whose
state is C<available>.

=back










=head2 B<REQUIRED> TargetSnapshotIdentifier => Str

  

The identifier given to the new manual snapshot.

Constraints:

=over

=item * Cannot be null, empty, or blank.

=item * Must contain from 1 to 255 alphanumeric characters or hyphens.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique for the AWS account that is making the request.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CopyClusterSnapshot in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

