
package Paws::CloudWatch::DescribeAlarmsForMetricOutput {
  use Moose;
  has MetricAlarms => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::MetricAlarm]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DescribeAlarmsForMetricOutput

=head1 ATTRIBUTES

=head2 MetricAlarms => ArrayRef[Paws::CloudWatch::MetricAlarm]

  

A list of information for each alarm with the specified metric.











=cut

