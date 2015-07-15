
package Paws::CloudWatch::ListMetricsOutput {
  use Moose;
  has Metrics => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::Metric]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::ListMetricsOutput

=head1 ATTRIBUTES

=head2 Metrics => ArrayRef[Paws::CloudWatch::Metric]

  

A list of metrics used to generate statistics for an AWS account.









=head2 NextToken => Str

  

A string that marks the start of the next batch of returned results.











=cut

