
package Paws::CloudWatchLogs::DeleteMetricFilter {
  use Moose;
  has filterName => (is => 'ro', isa => 'Str', required => 1);
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteMetricFilter');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DeleteMetricFilter - Arguments for method DeleteMetricFilter on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteMetricFilter on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method DeleteMetricFilter.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteMetricFilter.

As an example:

  $service_obj->DeleteMetricFilter(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> filterName => Str

  

The name of the metric filter to delete.










=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group that is associated with the metric filter to
delete.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteMetricFilter in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

