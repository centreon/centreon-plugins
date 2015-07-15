package Paws::CloudWatchLogs {
  use Moose;
  sub service { 'logs' }
  sub version { '2014-03-28' }
  sub target_prefix { 'Logs_20140328' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateLogGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::CreateLogGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateLogStream {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::CreateLogStream', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteLogGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DeleteLogGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteLogStream {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DeleteLogStream', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteMetricFilter {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DeleteMetricFilter', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRetentionPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DeleteRetentionPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSubscriptionFilter {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DeleteSubscriptionFilter', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeLogGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DescribeLogGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeLogStreams {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DescribeLogStreams', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMetricFilters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DescribeMetricFilters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSubscriptionFilters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::DescribeSubscriptionFilters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub FilterLogEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::FilterLogEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetLogEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::GetLogEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutLogEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::PutLogEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutMetricFilter {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::PutMetricFilter', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutRetentionPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::PutRetentionPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutSubscriptionFilter {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::PutSubscriptionFilter', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TestMetricFilter {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatchLogs::TestMetricFilter', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs - Perl Interface to AWS Amazon CloudWatch Logs

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CloudWatchLogs')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon CloudWatch Logs API Reference

This is the I<Amazon CloudWatch Logs API Reference>. Amazon CloudWatch
Logs enables you to monitor, store, and access your system,
application, and custom log files. This guide provides detailed
information about Amazon CloudWatch Logs actions, data types,
parameters, and errors. For detailed information about Amazon
CloudWatch Logs features and their associated API calls, go to the
Amazon CloudWatch Developer Guide.

Use the following links to get started using the I<Amazon CloudWatch
Logs API Reference>:

=over

=item * Actions: An alphabetical list of all Amazon CloudWatch Logs
actions.

=item * Data Types: An alphabetical list of all Amazon CloudWatch Logs
data types.

=item * Common Parameters: Parameters that all Query actions can use.

=item * Common Errors: Client and server errors that all actions can
return.

=item * Regions and Endpoints: Itemized regions and endpoints for all
AWS products.

=back

In addition to using the Amazon CloudWatch Logs API, you can also use
the following SDKs and third-party libraries to access Amazon
CloudWatch Logs programmatically.

=over

=item * AWS SDK for Java Documentation

=item * AWS SDK for .NET Documentation

=item * AWS SDK for PHP Documentation

=item * AWS SDK for Ruby Documentation

=back

Developers in the AWS developer community also provide their own
libraries, which you can find at the following AWS developer centers:

=over

=item * AWS Java Developer Center

=item * AWS PHP Developer Center

=item * AWS Python Developer Center

=item * AWS Ruby Developer Center

=item * AWS Windows and .NET Developer Center

=back










=head1 METHODS

=head2 CreateLogGroup(logGroupName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::CreateLogGroup>

Returns: nothing

  

Creates a new log group with the specified name. The name of the log
group must be unique within a region for an AWS account. You can create
up to 500 log groups per account.

You must use the following guidelines when naming a log group:

=over

=item * Log group names can be between 1 and 512 characters long.

=item * Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-'
(hyphen), '/' (forward slash), and '.' (period).

=back











=head2 CreateLogStream(logGroupName => Str, logStreamName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::CreateLogStream>

Returns: nothing

  

Creates a new log stream in the specified log group. The name of the
log stream must be unique within the log group. There is no limit on
the number of log streams that can exist in a log group.

You must use the following guidelines when naming a log stream:

=over

=item * Log stream names can be between 1 and 512 characters long.

=item * The ':' colon character is not allowed.

=back











=head2 DeleteLogGroup(logGroupName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::DeleteLogGroup>

Returns: nothing

  

Deletes the log group with the specified name and permanently deletes
all the archived log events associated with it.











=head2 DeleteLogStream(logGroupName => Str, logStreamName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::DeleteLogStream>

Returns: nothing

  

Deletes a log stream and permanently deletes all the archived log
events associated with it.











=head2 DeleteMetricFilter(filterName => Str, logGroupName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::DeleteMetricFilter>

Returns: nothing

  

Deletes a metric filter associated with the specified log group.











=head2 DeleteRetentionPolicy(logGroupName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::DeleteRetentionPolicy>

Returns: nothing

  

Deletes the retention policy of the specified log group. Log events
would not expire if they belong to log groups without a retention
policy.











=head2 DeleteSubscriptionFilter(filterName => Str, logGroupName => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::DeleteSubscriptionFilter>

Returns: nothing

  

Deletes a subscription filter associated with the specified log group.











=head2 DescribeLogGroups([limit => Int, logGroupNamePrefix => Str, nextToken => Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::DescribeLogGroups>

Returns: a L<Paws::CloudWatchLogs::DescribeLogGroupsResponse> instance

  

Returns all the log groups that are associated with the AWS account
making the request. The list returned in the response is ASCII-sorted
by log group name.

By default, this operation returns up to 50 log groups. If there are
more log groups to list, the response would contain a C<nextToken>
value in the response body. You can also limit the number of log groups
returned in the response by specifying the C<limit> parameter in the
request.











=head2 DescribeLogStreams(logGroupName => Str, [descending => Bool, limit => Int, logStreamNamePrefix => Str, nextToken => Str, orderBy => Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::DescribeLogStreams>

Returns: a L<Paws::CloudWatchLogs::DescribeLogStreamsResponse> instance

  

Returns all the log streams that are associated with the specified log
group. The list returned in the response is ASCII-sorted by log stream
name.

By default, this operation returns up to 50 log streams. If there are
more log streams to list, the response would contain a C<nextToken>
value in the response body. You can also limit the number of log
streams returned in the response by specifying the C<limit> parameter
in the request. This operation has a limit of five transactions per
second, after which transactions are throttled.











=head2 DescribeMetricFilters(logGroupName => Str, [filterNamePrefix => Str, limit => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::DescribeMetricFilters>

Returns: a L<Paws::CloudWatchLogs::DescribeMetricFiltersResponse> instance

  

Returns all the metrics filters associated with the specified log
group. The list returned in the response is ASCII-sorted by filter
name.

By default, this operation returns up to 50 metric filters. If there
are more metric filters to list, the response would contain a
C<nextToken> value in the response body. You can also limit the number
of metric filters returned in the response by specifying the C<limit>
parameter in the request.











=head2 DescribeSubscriptionFilters(logGroupName => Str, [filterNamePrefix => Str, limit => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::DescribeSubscriptionFilters>

Returns: a L<Paws::CloudWatchLogs::DescribeSubscriptionFiltersResponse> instance

  

Returns all the subscription filters associated with the specified log
group. The list returned in the response is ASCII-sorted by filter
name.

By default, this operation returns up to 50 subscription filters. If
there are more subscription filters to list, the response would contain
a C<nextToken> value in the response body. You can also limit the
number of subscription filters returned in the response by specifying
the C<limit> parameter in the request.











=head2 FilterLogEvents(logGroupName => Str, [endTime => Int, filterPattern => Str, interleaved => Bool, limit => Int, logStreamNames => ArrayRef[Str], nextToken => Str, startTime => Int])

Each argument is described in detail in: L<Paws::CloudWatchLogs::FilterLogEvents>

Returns: a L<Paws::CloudWatchLogs::FilterLogEventsResponse> instance

  

Retrieves log events, optionally filtered by a filter pattern from the
specified log group. You can provide an optional time range to filter
the results on the event C<timestamp>. You can limit the streams
searched to an explicit list of C<logStreamNames>.

By default, this operation returns as much matching log events as can
fit in a response size of 1MB, up to 10,000 log events, or all the
events found within a time-bounded scan window. If the response
includes a C<nextToken>, then there is more data to search, and the
search can be resumed with a new request providing the nextToken. The
response will contain a list of C<searchedLogStreams> that contains
information about which streams were searched in the request and
whether they have been searched completely or require further
pagination. The C<limit> parameter in the request. can be used to
specify the maximum number of events to return in a page.











=head2 GetLogEvents(logGroupName => Str, logStreamName => Str, [endTime => Int, limit => Int, nextToken => Str, startFromHead => Bool, startTime => Int])

Each argument is described in detail in: L<Paws::CloudWatchLogs::GetLogEvents>

Returns: a L<Paws::CloudWatchLogs::GetLogEventsResponse> instance

  

Retrieves log events from the specified log stream. You can provide an
optional time range to filter the results on the event C<timestamp>.

By default, this operation returns as much log events as can fit in a
response size of 1MB, up to 10,000 log events. The response will always
include a C<nextForwardToken> and a C<nextBackwardToken> in the
response body. You can use any of these tokens in subsequent
C<GetLogEvents> requests to paginate through events in either forward
or backward direction. You can also limit the number of log events
returned in the response by specifying the C<limit> parameter in the
request.











=head2 PutLogEvents(logEvents => ArrayRef[Paws::CloudWatchLogs::InputLogEvent], logGroupName => Str, logStreamName => Str, [sequenceToken => Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::PutLogEvents>

Returns: a L<Paws::CloudWatchLogs::PutLogEventsResponse> instance

  

Uploads a batch of log events to the specified log stream.

Every PutLogEvents request must include the C<sequenceToken> obtained
from the response of the previous request. An upload in a newly created
log stream does not require a C<sequenceToken>.

The batch of events must satisfy the following constraints:

=over

=item * The maximum batch size is 1,048,576 bytes, and this size is
calculated as the sum of all event messages in UTF-8, plus 26 bytes for
each log event.

=item * None of the log events in the batch can be more than 2 hours in
the future.

=item * None of the log events in the batch can be older than 14 days
or the retention period of the log group.

=item * The log events in the batch must be in chronological ordered by
their C<timestamp>.

=item * The maximum number of log events in a batch is 10,000.

=back











=head2 PutMetricFilter(filterName => Str, filterPattern => Str, logGroupName => Str, metricTransformations => ArrayRef[Paws::CloudWatchLogs::MetricTransformation])

Each argument is described in detail in: L<Paws::CloudWatchLogs::PutMetricFilter>

Returns: nothing

  

Creates or updates a metric filter and associates it with the specified
log group. Metric filters allow you to configure rules to extract
metric data from log events ingested through C<PutLogEvents> requests.

The maximum number of metric filters that can be associated with a log
group is 100.











=head2 PutRetentionPolicy(logGroupName => Str, retentionInDays => Int)

Each argument is described in detail in: L<Paws::CloudWatchLogs::PutRetentionPolicy>

Returns: nothing

  

Sets the retention of the specified log group. A retention policy
allows you to configure the number of days you want to retain log
events in the specified log group.











=head2 PutSubscriptionFilter(destinationArn => Str, filterName => Str, filterPattern => Str, logGroupName => Str, roleArn => Str)

Each argument is described in detail in: L<Paws::CloudWatchLogs::PutSubscriptionFilter>

Returns: nothing

  

Creates or updates a subscription filter and associates it with the
specified log group. Subscription filters allow you to subscribe to a
real-time stream of log events ingested through C<PutLogEvents>
requests and have them delivered to a specific destination. Currently
the only supported destination is an Amazon Kinesis stream belonging to
the same account as the subscription filter.

Currently there can only be one subscription filter associated with a
log group.











=head2 TestMetricFilter(filterPattern => Str, logEventMessages => ArrayRef[Str])

Each argument is described in detail in: L<Paws::CloudWatchLogs::TestMetricFilter>

Returns: a L<Paws::CloudWatchLogs::TestMetricFilterResponse> instance

  

Tests the filter pattern of a metric filter against a sample of log
event messages. You can use this operation to validate the correctness
of a metric filter pattern.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

