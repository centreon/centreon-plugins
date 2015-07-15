
package Paws::CloudWatchLogs::PutSubscriptionFilter {
  use Moose;
  has destinationArn => (is => 'ro', isa => 'Str', required => 1);
  has filterName => (is => 'ro', isa => 'Str', required => 1);
  has filterPattern => (is => 'ro', isa => 'Str', required => 1);
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has roleArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutSubscriptionFilter');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::PutSubscriptionFilter - Arguments for method PutSubscriptionFilter on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutSubscriptionFilter on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method PutSubscriptionFilter.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutSubscriptionFilter.

As an example:

  $service_obj->PutSubscriptionFilter(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> destinationArn => Str

  

The ARN of an Amazon Kinesis stream to deliver matching log events to.










=head2 B<REQUIRED> filterName => Str

  

A name for the subscription filter.










=head2 B<REQUIRED> filterPattern => Str

  

A valid CloudWatch Logs filter pattern for subscribing to a filtered
stream of log events.










=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group to associate the subscription filter with.










=head2 B<REQUIRED> roleArn => Str

  

The ARN of an IAM role that grants Amazon CloudWatch Logs permissions
to do Amazon Kinesis PutRecord requests on the desitnation stream.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutSubscriptionFilter in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

