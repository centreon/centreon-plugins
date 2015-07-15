
package Paws::ElastiCache::DescribeEvents {
  use Moose;
  has Duration => (is => 'ro', isa => 'Int');
  has EndTime => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has SourceIdentifier => (is => 'ro', isa => 'Str');
  has SourceType => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::EventsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeEventsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeEvents - Arguments for method DescribeEvents on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeEvents on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeEvents.

As an example:

  $service_obj->DescribeEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Duration => Int

  

The number of minutes' worth of events to retrieve.










=head2 EndTime => Str

  

The end of the time interval for which to retrieve events, specified in
ISO 8601 format.










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










=head2 SourceIdentifier => Str

  

The identifier of the event source for which events will be returned.
If not specified, then all sources are included in the response.










=head2 SourceType => Str

  

The event source to retrieve events for. If no value is specified, all
events are returned.

Valid values are: C<cache-cluster> | C<cache-parameter-group> |
C<cache-security-group> | C<cache-subnet-group>










=head2 StartTime => Str

  

The beginning of the time interval to retrieve events for, specified in
ISO 8601 format.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeEvents in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

