
package Paws::CloudWatchLogs::DescribeLogStreams {
  use Moose;
  has descending => (is => 'ro', isa => 'Bool');
  has limit => (is => 'ro', isa => 'Int');
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has logStreamNamePrefix => (is => 'ro', isa => 'Str');
  has nextToken => (is => 'ro', isa => 'Str');
  has orderBy => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeLogStreams');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::DescribeLogStreamsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeLogStreams - Arguments for method DescribeLogStreams on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeLogStreams on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method DescribeLogStreams.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeLogStreams.

As an example:

  $service_obj->DescribeLogStreams(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 descending => Bool

  

If set to true, results are returned in descending order. If you don't
specify a value or set it to false, results are returned in ascending
order.










=head2 limit => Int

  

The maximum number of items returned in the response. If you don't
specify a value, the request would return up to 50 items.










=head2 B<REQUIRED> logGroupName => Str

  

The log group name for which log streams are to be listed.










=head2 logStreamNamePrefix => Str

  

Will only return log streams that match the provided
logStreamNamePrefix. If you don't specify a value, no prefix filter is
applied.










=head2 nextToken => Str

  

A string token used for pagination that points to the next page of
results. It must be a value obtained from the response of the previous
C<DescribeLogStreams> request.










=head2 orderBy => Str

  

Specifies what to order the returned log streams by. Valid arguments
are 'LogStreamName' or 'LastEventTime'. If you don't specify a value,
results are ordered by LogStreamName. If 'LastEventTime' is chosen, the
request cannot also contain a logStreamNamePrefix.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeLogStreams in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

