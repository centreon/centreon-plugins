
package Paws::RDS::DescribeOptionGroups {
  use Moose;
  has EngineName => (is => 'ro', isa => 'Str');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has MajorEngineVersion => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has OptionGroupName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeOptionGroups');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::OptionGroups');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeOptionGroupsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeOptionGroups - Arguments for method DescribeOptionGroups on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeOptionGroups on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DescribeOptionGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeOptionGroups.

As an example:

  $service_obj->DescribeOptionGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EngineName => Str

  

Filters the list of option groups to only include groups associated
with a specific database engine.










=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

This parameter is not currently supported.










=head2 MajorEngineVersion => Str

  

Filters the list of option groups to only include groups associated
with a specific database engine version. If specified, then EngineName
must also be specified.










=head2 Marker => Str

  

An optional pagination token provided by a previous
DescribeOptionGroups request. If this parameter is specified, the
response includes only records beyond the marker, up to the value
specified by C<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified C<MaxRecords> value, a pagination
token called a marker is included in the response so that the remaining
results can be retrieved.

Default: 100

Constraints: minimum 20, maximum 100










=head2 OptionGroupName => Str

  

The name of the option group to describe. Cannot be supplied together
with EngineName or MajorEngineVersion.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeOptionGroups in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

