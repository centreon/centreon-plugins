
package Paws::CloudWatchLogs::FilterLogEvents {
  use Moose;
  has endTime => (is => 'ro', isa => 'Int');
  has filterPattern => (is => 'ro', isa => 'Str');
  has interleaved => (is => 'ro', isa => 'Bool');
  has limit => (is => 'ro', isa => 'Int');
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has logStreamNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');
  has startTime => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'FilterLogEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::FilterLogEventsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::FilterLogEvents - Arguments for method FilterLogEvents on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method FilterLogEvents on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method FilterLogEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to FilterLogEvents.

As an example:

  $service_obj->FilterLogEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 endTime => Int

  

A unix timestamp indicating the end time of the range for the request.
If provided, events with a timestamp later than this time will not be
returned.










=head2 filterPattern => Str

  

A valid CloudWatch Logs filter pattern to use for filtering the
response. If not provided, all the events are matched.










=head2 interleaved => Bool

  

If provided, the API will make a best effort to provide responses that
contain events from multiple log streams within the log group
interleaved in a single response. If not provided, all the matched log
events in the first log stream will be searched first, then those in
the next log stream, etc.










=head2 limit => Int

  

The maximum number of events to return in a page of results. Default is
10,000 events.










=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group to query.










=head2 logStreamNames => ArrayRef[Str]

  

Optional list of log stream names within the specified log group to
search. Defaults to all the log streams in the log group.










=head2 nextToken => Str

  

A pagination token obtained from a C<FilterLogEvents> response to
continue paginating the FilterLogEvents results.










=head2 startTime => Int

  

A unix timestamp indicating the start time of the range for the
request. If provided, events with a timestamp prior to this time will
not be returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method FilterLogEvents in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

