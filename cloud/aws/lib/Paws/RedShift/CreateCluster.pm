
package Paws::RedShift::CreateCluster {
  use Moose;
  has AllowVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AutomatedSnapshotRetentionPeriod => (is => 'ro', isa => 'Int');
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has ClusterIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has ClusterParameterGroupName => (is => 'ro', isa => 'Str');
  has ClusterSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has ClusterSubnetGroupName => (is => 'ro', isa => 'Str');
  has ClusterType => (is => 'ro', isa => 'Str');
  has ClusterVersion => (is => 'ro', isa => 'Str');
  has DBName => (is => 'ro', isa => 'Str');
  has ElasticIp => (is => 'ro', isa => 'Str');
  has Encrypted => (is => 'ro', isa => 'Bool');
  has HsmClientCertificateIdentifier => (is => 'ro', isa => 'Str');
  has HsmConfigurationIdentifier => (is => 'ro', isa => 'Str');
  has KmsKeyId => (is => 'ro', isa => 'Str');
  has MasterUsername => (is => 'ro', isa => 'Str', required => 1);
  has MasterUserPassword => (is => 'ro', isa => 'Str', required => 1);
  has NodeType => (is => 'ro', isa => 'Str', required => 1);
  has NumberOfNodes => (is => 'ro', isa => 'Int');
  has Port => (is => 'ro', isa => 'Int');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has PubliclyAccessible => (is => 'ro', isa => 'Bool');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');
  has VpcSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::CreateClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CreateCluster - Arguments for method CreateCluster on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCluster on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CreateCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCluster.

As an example:

  $service_obj->CreateCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowVersionUpgrade => Bool

  

If C<true>, major version upgrades can be applied during the
maintenance window to the Amazon Redshift engine that is running on the
cluster.

When a new major version of the Amazon Redshift engine is released, you
can request that the service automatically apply upgrades during the
maintenance window to the Amazon Redshift engine that is running on
your cluster.

Default: C<true>










=head2 AutomatedSnapshotRetentionPeriod => Int

  

The number of days that automated snapshots are retained. If the value
is 0, automated snapshots are disabled. Even if automated snapshots are
disabled, you can still create manual snapshots when you want with
CreateClusterSnapshot.

Default: C<1>

Constraints: Must be a value from 0 to 35.










=head2 AvailabilityZone => Str

  

The EC2 Availability Zone (AZ) in which you want Amazon Redshift to
provision the cluster. For example, if you have several EC2 instances
running in a specific Availability Zone, then you might want the
cluster to be provisioned in the same zone in order to decrease network
latency.

Default: A random, system-chosen Availability Zone in the region that
is specified by the endpoint.

Example: C<us-east-1d>

Constraint: The specified Availability Zone must be in the same region
as the current endpoint.










=head2 B<REQUIRED> ClusterIdentifier => Str

  

A unique identifier for the cluster. You use this identifier to refer
to the cluster for any subsequent cluster operations such as deleting
or modifying. The identifier also appears in the Amazon Redshift
console.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens.

=item * Alphabetic characters must be lowercase.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique for all clusters within an AWS account.

=back

Example: C<myexamplecluster>










=head2 ClusterParameterGroupName => Str

  

The name of the parameter group to be associated with this cluster.

Default: The default Amazon Redshift cluster parameter group. For
information about the default parameter group, go to Working with
Amazon Redshift Parameter Groups

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters or hyphens.

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=back










=head2 ClusterSecurityGroups => ArrayRef[Str]

  

A list of security groups to be associated with this cluster.

Default: The default cluster security group for Amazon Redshift.










=head2 ClusterSubnetGroupName => Str

  

The name of a cluster subnet group to be associated with this cluster.

If this parameter is not provided the resulting cluster will be
deployed outside virtual private cloud (VPC).










=head2 ClusterType => Str

  

The type of the cluster. When cluster type is specified as

=over

=item * C<single-node>, the B<NumberOfNodes> parameter is not required.

=item * C<multi-node>, the B<NumberOfNodes> parameter is required.

=back

Valid Values: C<multi-node> | C<single-node>

Default: C<multi-node>










=head2 ClusterVersion => Str

  

The version of the Amazon Redshift engine software that you want to
deploy on the cluster.

The version selected runs on all the nodes in the cluster.

Constraints: Only version 1.0 is currently available.

Example: C<1.0>










=head2 DBName => Str

  

The name of the first database to be created when the cluster is
created.

To create additional databases after the cluster is created, connect to
the cluster with a SQL client and use SQL commands to create a
database. For more information, go to Create a Database in the Amazon
Redshift Database Developer Guide.

Default: C<dev>

Constraints:

=over

=item * Must contain 1 to 64 alphanumeric characters.

=item * Must contain only lowercase letters.

=item * Cannot be a word that is reserved by the service. A list of
reserved words can be found in Reserved Words in the Amazon Redshift
Database Developer Guide.

=back










=head2 ElasticIp => Str

  

The Elastic IP (EIP) address for the cluster.

Constraints: The cluster must be provisioned in EC2-VPC and
publicly-accessible through an Internet gateway. For more information
about provisioning clusters in EC2-VPC, go to Supported Platforms to
Launch Your Cluster in the Amazon Redshift Cluster Management Guide.










=head2 Encrypted => Bool

  

If C<true>, the data in the cluster is encrypted at rest.

Default: false










=head2 HsmClientCertificateIdentifier => Str

  

Specifies the name of the HSM client certificate the Amazon Redshift
cluster uses to retrieve the data encryption keys stored in an HSM.










=head2 HsmConfigurationIdentifier => Str

  

Specifies the name of the HSM configuration that contains the
information the Amazon Redshift cluster can use to retrieve and store
keys in an HSM.










=head2 KmsKeyId => Str

  

The AWS Key Management Service (KMS) key ID of the encryption key that
you want to use to encrypt data in the cluster.










=head2 B<REQUIRED> MasterUsername => Str

  

The user name associated with the master user account for the cluster
that is being created.

Constraints:

=over

=item * Must be 1 - 128 alphanumeric characters.

=item * First character must be a letter.

=item * Cannot be a reserved word. A list of reserved words can be
found in Reserved Words in the Amazon Redshift Database Developer
Guide.

=back










=head2 B<REQUIRED> MasterUserPassword => Str

  

The password associated with the master user account for the cluster
that is being created.

Constraints:

=over

=item * Must be between 8 and 64 characters in length.

=item * Must contain at least one uppercase letter.

=item * Must contain at least one lowercase letter.

=item * Must contain one number.

=item * Can be any printable ASCII character (ASCII code 33 to 126)
except ' (single quote), " (double quote), \, /, @, or space.

=back










=head2 B<REQUIRED> NodeType => Str

  

The node type to be provisioned for the cluster. For information about
node types, go to Working with Clusters in the I<Amazon Redshift
Cluster Management Guide>.

Valid Values: C<ds1.xlarge> | C<ds1.8xlarge> | C<ds2.xlarge> |
C<ds2.8xlarge> | C<dc1.large> | C<dc1.8xlarge>.










=head2 NumberOfNodes => Int

  

The number of compute nodes in the cluster. This parameter is required
when the B<ClusterType> parameter is specified as C<multi-node>.

For information about determining how many nodes you need, go to
Working with Clusters in the I<Amazon Redshift Cluster Management
Guide>.

If you don't specify this parameter, you get a single-node cluster.
When requesting a multi-node cluster, you must specify the number of
nodes that you want in the cluster.

Default: C<1>

Constraints: Value must be at least 1 and no more than 100.










=head2 Port => Int

  

The port number on which the cluster accepts incoming connections.

The cluster is accessible only via the JDBC and ODBC connection
strings. Part of the connection string requires the port on which the
cluster will listen for incoming connections.

Default: C<5439>

Valid Values: C<1150-65535>










=head2 PreferredMaintenanceWindow => Str

  

The weekly time range (in UTC) during which automated cluster
maintenance can occur.

Format: C<ddd:hh24:mi-ddd:hh24:mi>

Default: A 30-minute window selected at random from an 8-hour block of
time per region, occurring on a random day of the week. For more
information about the time blocks for each region, see Maintenance
Windows in Amazon Redshift Cluster Management Guide.

Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun

Constraints: Minimum 30-minute window.










=head2 PubliclyAccessible => Bool

  

If C<true>, the cluster can be accessed from a public network.










=head2 Tags => ArrayRef[Paws::RedShift::Tag]

  

A list of tag instances.










=head2 VpcSecurityGroupIds => ArrayRef[Str]

  

A list of Virtual Private Cloud (VPC) security groups to be associated
with the cluster.

Default: The default VPC security group is associated with the cluster.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCluster in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

