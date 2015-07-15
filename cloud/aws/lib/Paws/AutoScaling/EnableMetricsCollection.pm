
package Paws::AutoScaling::EnableMetricsCollection {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Granularity => (is => 'ro', isa => 'Str', required => 1);
  has Metrics => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'EnableMetricsCollection');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::EnableMetricsCollection - Arguments for method EnableMetricsCollection on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method EnableMetricsCollection on the 
Auto Scaling service. Use the attributes of this class
as arguments to method EnableMetricsCollection.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to EnableMetricsCollection.

As an example:

  $service_obj->EnableMetricsCollection(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AutoScalingGroupName => Str

  

The name or ARN of the Auto Scaling group.










=head2 B<REQUIRED> Granularity => Str

  

The granularity to associate with the metrics to collect. The only
valid value is C<1Minute>.










=head2 Metrics => ArrayRef[Str]

  

One or more metrics. If you omit this parameter, all metrics are
enabled.

=over

=item *

C<GroupMinSize>

=item *

C<GroupMaxSize>

=item *

C<GroupDesiredCapacity>

=item *

C<GroupInServiceInstances>

=item *

C<GroupPendingInstances>

=item *

C<GroupStandbyInstances>

=item *

C<GroupTerminatingInstances>

=item *

C<GroupTotalInstances>

=back

Note that the C<GroupStandbyInstances> metric is not enabled by
default. You must explicitly request this metric.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method EnableMetricsCollection in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

