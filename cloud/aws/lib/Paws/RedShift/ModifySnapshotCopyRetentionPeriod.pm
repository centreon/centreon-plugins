
package Paws::RedShift::ModifySnapshotCopyRetentionPeriod {
  use Moose;
  has ClusterIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has RetentionPeriod => (is => 'ro', isa => 'Int', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifySnapshotCopyRetentionPeriod');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::ModifySnapshotCopyRetentionPeriodResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifySnapshotCopyRetentionPeriodResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ModifySnapshotCopyRetentionPeriod - Arguments for method ModifySnapshotCopyRetentionPeriod on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifySnapshotCopyRetentionPeriod on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method ModifySnapshotCopyRetentionPeriod.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifySnapshotCopyRetentionPeriod.

As an example:

  $service_obj->ModifySnapshotCopyRetentionPeriod(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClusterIdentifier => Str

  

The unique identifier of the cluster for which you want to change the
retention period for automated snapshots that are copied to a
destination region.

Constraints: Must be the valid name of an existing cluster that has
cross-region snapshot copy enabled.










=head2 B<REQUIRED> RetentionPeriod => Int

  

The number of days to retain automated snapshots in the destination
region after they are copied from the source region.

If you decrease the retention period for automated snapshots that are
copied to a destination region, Amazon Redshift will delete any
existing automated snapshots that were copied to the destination region
and that fall outside of the new retention period.

Constraints: Must be at least 1 and no more than 35.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifySnapshotCopyRetentionPeriod in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

