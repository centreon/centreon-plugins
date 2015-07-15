
package Paws::CloudWatch::DescribeAlarmsOutput {
  use Moose;
  has MetricAlarms => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::MetricAlarm]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DescribeAlarmsOutput

=head1 ATTRIBUTES

=head2 MetricAlarms => ArrayRef[Paws::CloudWatch::MetricAlarm]

  

A list of information for the specified alarms.









=head2 NextToken => Str

  

A string that marks the start of the next batch of returned results.











=cut

