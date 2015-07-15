package Paws::CloudWatch {
  use Moose;
  sub service { 'monitoring' }
  sub version { '2010-08-01' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub DeleteAlarms {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::DeleteAlarms', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAlarmHistory {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::DescribeAlarmHistory', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAlarms {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::DescribeAlarms', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAlarmsForMetric {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::DescribeAlarmsForMetric', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableAlarmActions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::DisableAlarmActions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableAlarmActions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::EnableAlarmActions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetMetricStatistics {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::GetMetricStatistics', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListMetrics {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::ListMetrics', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutMetricAlarm {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::PutMetricAlarm', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutMetricData {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::PutMetricData', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetAlarmState {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudWatch::SetAlarmState', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch - Perl Interface to AWS Amazon CloudWatch

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CloudWatch')->new;
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



This is the I<Amazon CloudWatch API Reference>. This guide provides
detailed information about Amazon CloudWatch actions, data types,
parameters, and errors. For detailed information about Amazon
CloudWatch features and their associated API calls, go to the Amazon
CloudWatch Developer Guide.

Amazon CloudWatch is a web service that enables you to publish,
monitor, and manage various metrics, as well as configure alarm actions
based on data from metrics. For more information about this product go
to http://aws.amazon.com/cloudwatch.

For information about the namespace, metric names, and dimensions that
other Amazon Web Services products use to send metrics to Cloudwatch,
go to Amazon CloudWatch Metrics, Namespaces, and Dimensions Reference
in the I<Amazon CloudWatch Developer Guide>.

Use the following links to get started using the I<Amazon CloudWatch
API Reference>:

=over

=item * Actions: An alphabetical list of all Amazon CloudWatch actions.

=item * Data Types: An alphabetical list of all Amazon CloudWatch data
types.

=item * Common Parameters: Parameters that all Query actions can use.

=item * Common Errors: Client and server errors that all actions can
return.

=item * Regions and Endpoints: Itemized regions and endpoints for all
AWS products.

=item * WSDL Location:
http://monitoring.amazonaws.com/doc/2010-08-01/CloudWatch.wsdl

=back

In addition to using the Amazon CloudWatch API, you can also use the
following SDKs and third-party libraries to access Amazon CloudWatch
programmatically.

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

=head2 DeleteAlarms(AlarmNames => ArrayRef[Str])

Each argument is described in detail in: L<Paws::CloudWatch::DeleteAlarms>

Returns: nothing

  

Deletes all specified alarms. In the event of an error, no alarms are
deleted.











=head2 DescribeAlarmHistory([AlarmName => Str, EndDate => Str, HistoryItemType => Str, MaxRecords => Int, NextToken => Str, StartDate => Str])

Each argument is described in detail in: L<Paws::CloudWatch::DescribeAlarmHistory>

Returns: a L<Paws::CloudWatch::DescribeAlarmHistoryOutput> instance

  

Retrieves history for the specified alarm. Filter alarms by date range
or item type. If an alarm name is not specified, Amazon CloudWatch
returns histories for all of the owner's alarms.











=head2 DescribeAlarms([ActionPrefix => Str, AlarmNamePrefix => Str, AlarmNames => ArrayRef[Str], MaxRecords => Int, NextToken => Str, StateValue => Str])

Each argument is described in detail in: L<Paws::CloudWatch::DescribeAlarms>

Returns: a L<Paws::CloudWatch::DescribeAlarmsOutput> instance

  

Retrieves alarms with the specified names. If no name is specified, all
alarms for the user are returned. Alarms can be retrieved by using only
a prefix for the alarm name, the alarm state, or a prefix for any
action.











=head2 DescribeAlarmsForMetric(MetricName => Str, Namespace => Str, [Dimensions => ArrayRef[Paws::CloudWatch::Dimension], Period => Int, Statistic => Str, Unit => Str])

Each argument is described in detail in: L<Paws::CloudWatch::DescribeAlarmsForMetric>

Returns: a L<Paws::CloudWatch::DescribeAlarmsForMetricOutput> instance

  

Retrieves all alarms for a single metric. Specify a statistic, period,
or unit to filter the set of alarms further.











=head2 DisableAlarmActions(AlarmNames => ArrayRef[Str])

Each argument is described in detail in: L<Paws::CloudWatch::DisableAlarmActions>

Returns: nothing

  

Disables actions for the specified alarms. When an alarm's actions are
disabled the alarm's state may change, but none of the alarm's actions
will execute.











=head2 EnableAlarmActions(AlarmNames => ArrayRef[Str])

Each argument is described in detail in: L<Paws::CloudWatch::EnableAlarmActions>

Returns: nothing

  

Enables actions for the specified alarms.











=head2 GetMetricStatistics(EndTime => Str, MetricName => Str, Namespace => Str, Period => Int, StartTime => Str, Statistics => ArrayRef[Str], [Dimensions => ArrayRef[Paws::CloudWatch::Dimension], Unit => Str])

Each argument is described in detail in: L<Paws::CloudWatch::GetMetricStatistics>

Returns: a L<Paws::CloudWatch::GetMetricStatisticsOutput> instance

  

Gets statistics for the specified metric.

The maximum number of data points returned from a single
C<GetMetricStatistics> request is 1,440, wereas the maximum number of
data points that can be queried is 50,850. If you make a request that
generates more than 1,440 data points, Amazon CloudWatch returns an
error. In such a case, you can alter the request by narrowing the
specified time range or increasing the specified period. Alternatively,
you can make multiple requests across adjacent time ranges.

Amazon CloudWatch aggregates data points based on the length of the
C<period> that you specify. For example, if you request statistics with
a one-minute granularity, Amazon CloudWatch aggregates data points with
time stamps that fall within the same one-minute period. In such a
case, the data points queried can greatly outnumber the data points
returned.

The following examples show various statistics allowed by the data
point query maximum of 50,850 when you call C<GetMetricStatistics> on
Amazon EC2 instances with detailed (one-minute) monitoring enabled:

=over

=item * Statistics for up to 400 instances for a span of one hour

=item * Statistics for up to 35 instances over a span of 24 hours

=item * Statistics for up to 2 instances over a span of 2 weeks

=back

For information about the namespace, metric names, and dimensions that
other Amazon Web Services products use to send metrics to Cloudwatch,
go to Amazon CloudWatch Metrics, Namespaces, and Dimensions Reference
in the I<Amazon CloudWatch Developer Guide>.











=head2 ListMetrics([Dimensions => ArrayRef[Paws::CloudWatch::DimensionFilter], MetricName => Str, Namespace => Str, NextToken => Str])

Each argument is described in detail in: L<Paws::CloudWatch::ListMetrics>

Returns: a L<Paws::CloudWatch::ListMetricsOutput> instance

  

Returns a list of valid metrics stored for the AWS account owner.
Returned metrics can be used with GetMetricStatistics to obtain
statistical data for a given metric.











=head2 PutMetricAlarm(AlarmName => Str, ComparisonOperator => Str, EvaluationPeriods => Int, MetricName => Str, Namespace => Str, Period => Int, Statistic => Str, Threshold => Num, [ActionsEnabled => Bool, AlarmActions => ArrayRef[Str], AlarmDescription => Str, Dimensions => ArrayRef[Paws::CloudWatch::Dimension], InsufficientDataActions => ArrayRef[Str], OKActions => ArrayRef[Str], Unit => Str])

Each argument is described in detail in: L<Paws::CloudWatch::PutMetricAlarm>

Returns: nothing

  

Creates or updates an alarm and associates it with the specified Amazon
CloudWatch metric. Optionally, this operation can associate one or more
Amazon Simple Notification Service resources with the alarm.

When this operation creates an alarm, the alarm state is immediately
set to C<INSUFFICIENT_DATA>. The alarm is evaluated and its
C<StateValue> is set appropriately. Any actions associated with the
C<StateValue> is then executed.











=head2 PutMetricData(MetricData => ArrayRef[Paws::CloudWatch::MetricDatum], Namespace => Str)

Each argument is described in detail in: L<Paws::CloudWatch::PutMetricData>

Returns: nothing

  

Publishes metric data points to Amazon CloudWatch. Amazon Cloudwatch
associates the data points with the specified metric. If the specified
metric does not exist, Amazon CloudWatch creates the metric. It can
take up to fifteen minutes for a new metric to appear in calls to the
ListMetrics action.

The size of a PutMetricData request is limited to 8 KB for HTTP GET
requests and 40 KB for HTTP POST requests.

Although the C<Value> parameter accepts numbers of type C<Double>,
Amazon CloudWatch truncates values with very large exponents. Values
with base-10 exponents greater than 126 (1 x 10^126) are truncated.
Likewise, values with base-10 exponents less than -130 (1 x 10^-130)
are also truncated.

Data that is timestamped 24 hours or more in the past may take in
excess of 48 hours to become available from submission time using
C<GetMetricStatistics>.











=head2 SetAlarmState(AlarmName => Str, StateReason => Str, StateValue => Str, [StateReasonData => Str])

Each argument is described in detail in: L<Paws::CloudWatch::SetAlarmState>

Returns: nothing

  

Temporarily sets the state of an alarm. When the updated C<StateValue>
differs from the previous value, the action configured for the
appropriate state is invoked. This is not a permanent change. The next
periodic alarm check (in about a minute) will set the alarm to its
actual state.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

