
package Paws::CloudWatch::ListMetrics {
  use Moose;
  has Dimensions => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::DimensionFilter]');
  has MetricName => (is => 'ro', isa => 'Str');
  has Namespace => (is => 'ro', isa => 'Str');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListMetrics');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatch::ListMetricsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListMetricsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::ListMetrics - Arguments for method ListMetrics on Paws::CloudWatch

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListMetrics on the 
Amazon CloudWatch service. Use the attributes of this class
as arguments to method ListMetrics.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListMetrics.

As an example:

  $service_obj->ListMetrics(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Dimensions => ArrayRef[Paws::CloudWatch::DimensionFilter]

  

A list of dimensions to filter against.










=head2 MetricName => Str

  

The name of the metric to filter against.










=head2 Namespace => Str

  

The namespace to filter against.










=head2 NextToken => Str

  

The token returned by a previous call to indicate that there is more
data available.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListMetrics in L<Paws::CloudWatch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

