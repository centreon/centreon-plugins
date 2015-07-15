
package Paws::RedShift::RestoreFromClusterSnapshot {
  use Moose;
  has AllowVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AutomatedSnapshotRetentionPeriod => (is => 'ro', isa => 'Int');
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has ClusterIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has ClusterParameterGroupName => (is => 'ro', isa => 'Str');
  has ClusterSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has ClusterSubnetGroupName => (is => 'ro', isa => 'Str');
  has ElasticIp => (is => 'ro', isa => 'Str');
  has HsmClientCertificateIdentifier => (is => 'ro', isa => 'Str');
  has HsmConfigurationIdentifier => (is => 'ro', isa => 'Str');
  has KmsKeyId => (is => 'ro', isa => 'Str');
  has NodeType => (is => 'ro', isa => 'Str');
  has OwnerAccount => (is => 'ro', isa => 'Str');
  has Port => (is => 'ro', isa => 'Int');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has PubliclyAccessible => (is => 'ro', isa => 'Bool');
  has SnapshotClusterIdentifier => (is => 'ro', isa => 'Str');
  has SnapshotIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has VpcSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RestoreFromClusterSnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::RestoreFromClusterSnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RestoreFromClusterSnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::RestoreFromClusterSnapshot - Arguments for method RestoreFromClusterSnapshot on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method RestoreFromClusterSnapshot on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method RestoreFromClusterSnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RestoreFromClusterSnapshot.

As an example:

  $service_obj->RestoreFromClusterSnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowVersionUpgrade => Bool

  

If C<true>, major version upgrades can be applied during the
maintenance window to the Amazon Redshift engine that is running on the
cluster.

Default: C<true>










=head2 AutomatedSnapshotRetentionPeriod => Int

  

The number of days that automated snapshots are retained. If the value
is 0, automated snapshots are disabled. Even if automated snapshots are
disabled, you can still create manual snapshots when you want with
CreateClusterSnapshot.

Default: The value selected for the cluster from which the snapshot was
taken.

Constraints: Must be a value from 0 to 35.










=head2 AvailabilityZone => Str

  

The Amazon EC2 Availability Zone in which to restore the cluster.

Default: A random, system-chosen Availability Zone.

Example: C<us-east-1a>










=head2 B<REQUIRED> ClusterIdentifier => Str

  

The identifier of the cluster that will be created from restoring the
snapshot.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens.

=item * Alphabetic characters must be lowercase.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique for all clusters within an AWS account.

=back










=head2 ClusterParameterGroupName => Str

  

The name of the parameter group to be associated with this cluster.

Default: The default Amazon Redshift cluster parameter group. For
information about the default parameter group, go to Working with
Amazon Redshift Parameter Groups.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters or hyphens.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=back










=head2 ClusterSecurityGroups => ArrayRef[Str]

  

A list of security groups to be associated with this cluster.

Default: The default cluster security group for Amazon Redshift.

Cluster security groups only apply to clusters outside of VPCs.










=head2 ClusterSubnetGroupName => Str

  

The name of the subnet group where you want to cluster restored.

A snapshot of cluster in VPC can be restored only in VPC. Therefore,
you must provide subnet group name where you want the cluster restored.










=head2 ElasticIp => Str

  

The elastic IP (EIP) address for the cluster.










=head2 HsmClientCertificateIdentifier => Str

  

Specifies the name of the HSM client certificate the Amazon Redshift
cluster uses to retrieve the data encryption keys stored in an HSM.










=head2 HsmConfigurationIdentifier => Str

  

Specifies the name of the HSM configuration that contains the
information the Amazon Redshift cluster can use to retrieve and store
keys in an HSM.










=head2 KmsKeyId => Str

  

The AWS Key Management Service (KMS) key ID of the encryption key that
you want to use to encrypt data in the cluster that you restore from a
shared snapshot.










=head2 NodeType => Str

  

The node type that the restored cluster will be provisioned with.

Default: The node type of the cluster from which the snapshot was
taken. You can modify this if you are using any DS node type. In that
case, you can choose to restore into another DS node type of the same
size. For example, you can restore ds1.8xlarge into ds2.8xlarge, or
ds2.xlarge into ds1.xlarge. If you have a DC instance type, you must
restore into that same instance type and size. In other words, you can
only restore a dc1.large instance type into another dc1.large instance
type. For more information about node types, see About Clusters and
Nodes in the I<Amazon Redshift Cluster Management Guide>










=head2 OwnerAccount => Str

  

The AWS customer account used to create or copy the snapshot. Required
if you are restoring a snapshot you do not own, optional if you own the
snapshot.










=head2 Port => Int

  

The port number on which the cluster accepts connections.

Default: The same port as the original cluster.

Constraints: Must be between C<1115> and C<65535>.










=head2 PreferredMaintenanceWindow => Str

  

The weekly time range (in UTC) during which automated cluster
maintenance can occur.

Format: C<ddd:hh24:mi-ddd:hh24:mi>

Default: The value selected for the cluster from which the snapshot was
taken. For more information about the time blocks for each region, see
Maintenance Windows in Amazon Redshift Cluster Management Guide.

Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun

Constraints: Minimum 30-minute window.










=head2 PubliclyAccessible => Bool

  

If C<true>, the cluster can be accessed from a public network.










=head2 SnapshotClusterIdentifier => Str

  

The name of the cluster the source snapshot was created from. This
parameter is required if your IAM user has a policy containing a
snapshot resource element that specifies anything other than * for the
cluster name.










=head2 B<REQUIRED> SnapshotIdentifier => Str

  

The name of the snapshot from which to create the new cluster. This
parameter isn't case sensitive.

Example: C<my-snapshot-id>










=head2 VpcSecurityGroupIds => ArrayRef[Str]

  

A list of Virtual Private Cloud (VPC) security groups to be associated
with the cluster.

Default: The default VPC security group is associated with the cluster.

VPC security groups only apply to clusters in VPCs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RestoreFromClusterSnapshot in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

