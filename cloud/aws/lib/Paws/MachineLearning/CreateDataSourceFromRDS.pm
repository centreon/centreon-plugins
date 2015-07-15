
package Paws::MachineLearning::CreateDataSourceFromRDS {
  use Moose;
  has ComputeStatistics => (is => 'ro', isa => 'Bool');
  has DataSourceId => (is => 'ro', isa => 'Str', required => 1);
  has DataSourceName => (is => 'ro', isa => 'Str');
  has RDSData => (is => 'ro', isa => 'Paws::MachineLearning::RDSDataSpec', required => 1);
  has RoleARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDataSourceFromRDS');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::CreateDataSourceFromRDSOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateDataSourceFromRDS - Arguments for method CreateDataSourceFromRDS on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDataSourceFromRDS on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method CreateDataSourceFromRDS.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDataSourceFromRDS.

As an example:

  $service_obj->CreateDataSourceFromRDS(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ComputeStatistics => Bool

  

The compute statistics for a C<DataSource>. The statistics are
generated from the observation data referenced by a C<DataSource>.
Amazon ML uses the statistics internally during an C<MLModel> training.
This parameter must be set to C<true> if the C<>DataSourceC<> needs to
be used for C<MLModel> training.










=head2 B<REQUIRED> DataSourceId => Str

  

A user-supplied ID that uniquely identifies the C<DataSource>.
Typically, an Amazon Resource Number (ARN) becomes the ID for a
C<DataSource>.










=head2 DataSourceName => Str

  

A user-supplied name or description of the C<DataSource>.










=head2 B<REQUIRED> RDSData => Paws::MachineLearning::RDSDataSpec

  

The data specification of an Amazon RDS C<DataSource>:

=over

=item *

DatabaseInformation -

=over

=item * C<DatabaseName > - Name of the Amazon RDS database.

=item * C< InstanceIdentifier > - Unique identifier for the Amazon RDS
database instance.

=back

=item *

DatabaseCredentials - AWS Identity and Access Management (IAM)
credentials that are used to connect to the Amazon RDS database.

=item *

ResourceRole - Role (DataPipelineDefaultResourceRole) assumed by an
Amazon Elastic Compute Cloud (EC2) instance to carry out the copy task
from Amazon RDS to Amazon S3. For more information, see Role templates
for data pipelines.

=item *

ServiceRole - Role (DataPipelineDefaultRole) assumed by the AWS Data
Pipeline service to monitor the progress of the copy task from Amazon
RDS to Amazon Simple Storage Service (S3). For more information, see
Role templates for data pipelines.

=item *

SecurityInfo - Security information to use to access an Amazon RDS
instance. You need to set up appropriate ingress rules for the security
entity IDs provided to allow access to the Amazon RDS instance. Specify
a [C<SubnetId>, C<SecurityGroupIds>] pair for a VPC-based Amazon RDS
instance.

=item *

SelectSqlQuery - Query that is used to retrieve the observation data
for the C<Datasource>.

=item *

S3StagingLocation - Amazon S3 location for staging RDS data. The data
retrieved from Amazon RDS using C<SelectSqlQuery> is stored in this
location.

=item *

DataSchemaUri - Amazon S3 location of the C<DataSchema>.

=item *

DataSchema - A JSON string representing the schema. This is not
required if C<DataSchemaUri> is specified.

=item *

DataRearrangement - A JSON string representing the splitting
requirement of a C<Datasource>.

Sample - C< "{\"randomSeed\":\"some-random-seed\",
\"splitting\":{\"percentBegin\":10,\"percentEnd\":60}}">

=back










=head2 B<REQUIRED> RoleARN => Str

  

The role that Amazon ML assumes on behalf of the user to create and
activate a data pipeline in the userE<acirc>E<128>E<153>s account and
copy data (using the C<SelectSqlQuery>) query from Amazon RDS to Amazon
S3.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDataSourceFromRDS in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

