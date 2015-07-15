
package Paws::CloudWatchLogs::TestMetricFilter {
  use Moose;
  has filterPattern => (is => 'ro', isa => 'Str', required => 1);
  has logEventMessages => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TestMetricFilter');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::TestMetricFilterResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::TestMetricFilter - Arguments for method TestMetricFilter on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method TestMetricFilter on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method TestMetricFilter.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TestMetricFilter.

As an example:

  $service_obj->TestMetricFilter(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> filterPattern => Str

  

=head2 B<REQUIRED> logEventMessages => ArrayRef[Str]

  

A list of log event messages to test.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TestMetricFilter in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

