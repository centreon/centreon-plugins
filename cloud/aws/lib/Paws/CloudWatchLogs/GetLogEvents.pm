
package Paws::CloudWatchLogs::GetLogEvents {
  use Moose;
  has endTime => (is => 'ro', isa => 'Int');
  has limit => (is => 'ro', isa => 'Int');
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has logStreamName => (is => 'ro', isa => 'Str', required => 1);
  has nextToken => (is => 'ro', isa => 'Str');
  has startFromHead => (is => 'ro', isa => 'Bool');
  has startTime => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetLogEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::GetLogEventsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::GetLogEvents - Arguments for method GetLogEvents on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetLogEvents on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method GetLogEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetLogEvents.

As an example:

  $service_obj->GetLogEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 endTime => Int

  

=head2 limit => Int

  

The maximum number of log events returned in the response. If you don't
specify a value, the request would return as many log events as can fit
in a response size of 1MB, up to 10,000 log events.










=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group to query.










=head2 B<REQUIRED> logStreamName => Str

  

The name of the log stream to query.










=head2 nextToken => Str

  

A string token used for pagination that points to the next page of
results. It must be a value obtained from the C<nextForwardToken> or
C<nextBackwardToken> fields in the response of the previous
C<GetLogEvents> request.










=head2 startFromHead => Bool

  

If set to true, the earliest log events would be returned first. The
default is false (the latest log events are returned first).










=head2 startTime => Int

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetLogEvents in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

