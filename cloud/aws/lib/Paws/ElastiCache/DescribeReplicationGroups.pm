
package Paws::ElastiCache::DescribeReplicationGroups {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has ReplicationGroupId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReplicationGroups');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::ReplicationGroupMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeReplicationGroupsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeReplicationGroups - Arguments for method DescribeReplicationGroups on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReplicationGroups on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeReplicationGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReplicationGroups.

As an example:

  $service_obj->DescribeReplicationGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional marker returned from a prior request. Use this marker for
pagination of results from this action. If this parameter is specified,
the response includes only records beyond the marker, up to the value
specified by I<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified C<MaxRecords> value, a marker is
included in the response so that the remaining results can be
retrieved.

Default: 100

Constraints: minimum 20; maximum 100.










=head2 ReplicationGroupId => Str

  

The identifier for the replication group to be described. This
parameter is not case sensitive.

If you do not specify this parameter, information about all replication
groups is returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReplicationGroups in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

