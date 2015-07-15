
package Paws::CloudWatchLogs::PutLogEvents {
  use Moose;
  has logEvents => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::InputLogEvent]', required => 1);
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has logStreamName => (is => 'ro', isa => 'Str', required => 1);
  has sequenceToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutLogEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::PutLogEventsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::PutLogEvents - Arguments for method PutLogEvents on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutLogEvents on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method PutLogEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutLogEvents.

As an example:

  $service_obj->PutLogEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> logEvents => ArrayRef[Paws::CloudWatchLogs::InputLogEvent]

  

=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group to put log events to.










=head2 B<REQUIRED> logStreamName => Str

  

The name of the log stream to put log events to.










=head2 sequenceToken => Str

  

A string token that must be obtained from the response of the previous
C<PutLogEvents> request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutLogEvents in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

