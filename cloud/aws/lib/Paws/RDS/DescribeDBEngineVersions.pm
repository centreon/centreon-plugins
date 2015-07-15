
package Paws::RDS::DescribeDBEngineVersions {
  use Moose;
  has DBParameterGroupFamily => (is => 'ro', isa => 'Str');
  has DefaultOnly => (is => 'ro', isa => 'Bool');
  has Engine => (is => 'ro', isa => 'Str');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has ListSupportedCharacterSets => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDBEngineVersions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DBEngineVersionMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeDBEngineVersionsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeDBEngineVersions - Arguments for method DescribeDBEngineVersions on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDBEngineVersions on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DescribeDBEngineVersions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDBEngineVersions.

As an example:

  $service_obj->DescribeDBEngineVersions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DBParameterGroupFamily => Str

  

The name of a specific DB parameter group family to return details for.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 DefaultOnly => Bool

  

Indicates that only the default version of the specified engine or
engine and major version combination is returned.










=head2 Engine => Str

  

The database engine to return.










=head2 EngineVersion => Str

  

The database engine version to return.

Example: C<5.1.49>










=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

Not currently supported.










=head2 ListSupportedCharacterSets => Bool

  

If this parameter is specified, and if the requested engine supports
the CharacterSetName parameter for CreateDBInstance, the response
includes a list of supported character sets for each engine version.










=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more than
the C<MaxRecords> value is available, a pagination token called a
marker is included in the response so that the following results can be
retrieved.

Default: 100

Constraints: minimum 20, maximum 100












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDBEngineVersions in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

