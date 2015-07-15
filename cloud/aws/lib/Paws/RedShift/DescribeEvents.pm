
package Paws::RedShift::DescribeEvents {
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
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::EventsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeEventsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::DescribeEvents - Arguments for method DescribeEvents on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeEvents on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method DescribeEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeEvents.

As an example:

  $service_obj->DescribeEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Duration => Int

  

The number of minutes prior to the time of the request for which to
retrieve events. For example, if the request is sent at 18:00 and you
specify a duration of 60, then only events which have occurred after
17:00 will be returned.

Default: C<60>










=head2 EndTime => Str

  

The end of the time interval for which to retrieve events, specified in
ISO 8601 format. For more information about ISO 8601, go to the ISO8601
Wikipedia page.

Example: C<2009-07-08T18:00Z>










=head2 Marker => Str

  

An optional parameter that specifies the starting point to return a set
of response records. When the results of a DescribeEvents request
exceed the value specified in C<MaxRecords>, AWS returns a value in the
C<Marker> field of the response. You can retrieve the next set of
response records by providing the returned marker value in the
C<Marker> parameter and retrying the request.










=head2 MaxRecords => Int

  

The maximum number of response records to return in each call. If the
number of remaining response records exceeds the specified
C<MaxRecords> value, a value is returned in a C<marker> field of the
response. You can retrieve the next set of records by retrying the
command with the returned marker value.

Default: C<100>

Constraints: minimum 20, maximum 100.










=head2 SourceIdentifier => Str

  

The identifier of the event source for which events will be returned.
If this parameter is not specified, then all sources are included in
the response.

Constraints:

If I<SourceIdentifier> is supplied, I<SourceType> must also be
provided.

=over

=item * Specify a cluster identifier when I<SourceType> is C<cluster>.

=item * Specify a cluster security group name when I<SourceType> is
C<cluster-security-group>.

=item * Specify a cluster parameter group name when I<SourceType> is
C<cluster-parameter-group>.

=item * Specify a cluster snapshot identifier when I<SourceType> is
C<cluster-snapshot>.

=back










=head2 SourceType => Str

  

The event source to retrieve events for. If no value is specified, all
events are returned.

Constraints:

If I<SourceType> is supplied, I<SourceIdentifier> must also be
provided.

=over

=item * Specify C<cluster> when I<SourceIdentifier> is a cluster
identifier.

=item * Specify C<cluster-security-group> when I<SourceIdentifier> is a
cluster security group name.

=item * Specify C<cluster-parameter-group> when I<SourceIdentifier> is
a cluster parameter group name.

=item * Specify C<cluster-snapshot> when I<SourceIdentifier> is a
cluster snapshot identifier.

=back










=head2 StartTime => Str

  

The beginning of the time interval to retrieve events for, specified in
ISO 8601 format. For more information about ISO 8601, go to the ISO8601
Wikipedia page.

Example: C<2009-07-08T18:00Z>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeEvents in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

