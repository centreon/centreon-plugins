
package Paws::RedShift::ModifyCluster {
  use Moose;
  has AllowVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AutomatedSnapshotRetentionPeriod => (is => 'ro', isa => 'Int');
  has ClusterIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has ClusterParameterGroupName => (is => 'ro', isa => 'Str');
  has ClusterSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has ClusterType => (is => 'ro', isa => 'Str');
  has ClusterVersion => (is => 'ro', isa => 'Str');
  has HsmClientCertificateIdentifier => (is => 'ro', isa => 'Str');
  has HsmConfigurationIdentifier => (is => 'ro', isa => 'Str');
  has MasterUserPassword => (is => 'ro', isa => 'Str');
  has NewClusterIdentifier => (is => 'ro', isa => 'Str');
  has NodeType => (is => 'ro', isa => 'Str');
  has NumberOfNodes => (is => 'ro', isa => 'Int');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has VpcSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::ModifyClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ModifyCluster - Arguments for method ModifyCluster on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyCluster on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method ModifyCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyCluster.

As an example:

  $service_obj->ModifyCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowVersionUpgrade => Bool

  

If C<true>, major version upgrades will be applied automatically to the
cluster during the maintenance window.

Default: C<false>










=head2 AutomatedSnapshotRetentionPeriod => Int

  

The number of days that automated snapshots are retained. If the value
is 0, automated snapshots are disabled. Even if automated snapshots are
disabled, you can still create manual snapshots when you want with
CreateClusterSnapshot.

If you decrease the automated snapshot retention period from its
current value, existing automated snapshots that fall outside of the
new retention period will be immediately deleted.

Default: Uses existing setting.

Constraints: Must be a value from 0 to 35.










=head2 B<REQUIRED> ClusterIdentifier => Str

  

The unique identifier of the cluster to be modified.

Example: C<examplecluster>










=head2 ClusterParameterGroupName => Str

  

The name of the cluster parameter group to apply to this cluster. This
change is applied only after the cluster is rebooted. To reboot a
cluster use RebootCluster.

Default: Uses existing setting.

Constraints: The cluster parameter group must be in the same parameter
group family that matches the cluster version.










=head2 ClusterSecurityGroups => ArrayRef[Str]

  

A list of cluster security groups to be authorized on this cluster.
This change is asynchronously applied as soon as possible.

Security groups currently associated with the cluster, and not in the
list of groups to apply, will be revoked from the cluster.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 ClusterType => Str

  

The new cluster type.

When you submit your cluster resize request, your existing cluster goes
into a read-only mode. After Amazon Redshift provisions a new cluster
based on your resize requirements, there will be outage for a period
while the old cluster is deleted and your connection is switched to the
new cluster. You can use DescribeResize to track the progress of the
resize request.

Valid Values: C< multi-node | single-node>










=head2 ClusterVersion => Str

  

The new version number of the Amazon Redshift engine to upgrade to.

For major version upgrades, if a non-default cluster parameter group is
currently in use, a new cluster parameter group in the cluster
parameter group family for the new version must be specified. The new
cluster parameter group can be the default for that cluster parameter
group family. For more information about parameters and parameter
groups, go to Amazon Redshift Parameter Groups in the I<Amazon Redshift
Cluster Management Guide>.

Example: C<1.0>










=head2 HsmClientCertificateIdentifier => Str

  

Specifies the name of the HSM client certificate the Amazon Redshift
cluster uses to retrieve the data encryption keys stored in an HSM.










=head2 HsmConfigurationIdentifier => Str

  

Specifies the name of the HSM configuration that contains the
information the Amazon Redshift cluster can use to retrieve and store
keys in an HSM.










=head2 MasterUserPassword => Str

  

The new password for the cluster master user. This change is
asynchronously applied as soon as possible. Between the time of the
request and the completion of the request, the C<MasterUserPassword>
element exists in the C<PendingModifiedValues> element of the operation
response. Operations never return the password, so this operation
provides a way to regain access to the master user account for a
cluster if the password is lost.

Default: Uses existing setting.

Constraints:

=over

=item * Must be between 8 and 64 characters in length.

=item * Must contain at least one uppercase letter.

=item * Must contain at least one lowercase letter.

=item * Must contain one number.

=item * Can be any printable ASCII character (ASCII code 33 to 126)
except ' (single quote), " (double quote), \, /, @, or space.

=back










=head2 NewClusterIdentifier => Str

  

The new identifier for the cluster.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens.

=item * Alphabetic characters must be lowercase.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique for all clusters within an AWS account.

=back

Example: C<examplecluster>










=head2 NodeType => Str

  

The new node type of the cluster. If you specify a new node type, you
must also specify the number of nodes parameter.

When you submit your request to resize a cluster, Amazon Redshift sets
access permissions for the cluster to read-only. After Amazon Redshift
provisions a new cluster according to your resize requirements, there
will be a temporary outage while the old cluster is deleted and your
connection is switched to the new cluster. When the new connection is
complete, the original access permissions for the cluster are restored.
You can use DescribeResize to track the progress of the resize request.

Valid Values: C< ds1.xlarge> | C<ds1.8xlarge> | C< ds2.xlarge> |
C<ds2.8xlarge> | C<dc1.large> | C<dc1.8xlarge>.










=head2 NumberOfNodes => Int

  

The new number of nodes of the cluster. If you specify a new number of
nodes, you must also specify the node type parameter.

When you submit your request to resize a cluster, Amazon Redshift sets
access permissions for the cluster to read-only. After Amazon Redshift
provisions a new cluster according to your resize requirements, there
will be a temporary outage while the old cluster is deleted and your
connection is switched to the new cluster. When the new connection is
complete, the original access permissions for the cluster are restored.
You can use DescribeResize to track the progress of the resize request.

Valid Values: Integer greater than C<0>.










=head2 PreferredMaintenanceWindow => Str

  

The weekly time range (in UTC) during which system maintenance can
occur, if necessary. If system maintenance is necessary during the
window, it may result in an outage.

This maintenance window change is made immediately. If the new
maintenance window indicates the current time, there must be at least
120 minutes between the current time and end of the window in order to
ensure that pending changes are applied.

Default: Uses existing setting.

Format: ddd:hh24:mi-ddd:hh24:mi, for example C<wed:07:30-wed:08:00>.

Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun

Constraints: Must be at least 30 minutes.










=head2 VpcSecurityGroupIds => ArrayRef[Str]

  

A list of virtual private cloud (VPC) security groups to be associated
with the cluster.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyCluster in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

