
package Paws::CloudWatch::GetMetricStatisticsOutput;
  use Moose;
  has Datapoints => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::Datapoint]');
  has Label => (is => 'ro', isa => 'Str');


1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::GetMetricStatisticsOutput

=head1 ATTRIBUTES

=head2 Datapoints => ArrayRef[Paws::CloudWatch::Datapoint]

  

The datapoints for the specified metric.









=head2 Label => Str

  

A label describing the specified metric.











=cut

