
package Paws::CloudWatch::DescribeAlarmHistoryOutput {
  use Moose;
  has AlarmHistoryItems => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::AlarmHistoryItem]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DescribeAlarmHistoryOutput

=head1 ATTRIBUTES

=head2 AlarmHistoryItems => ArrayRef[Paws::CloudWatch::AlarmHistoryItem]

  

A list of alarm histories in JSON format.









=head2 NextToken => Str

  

A string that marks the start of the next batch of returned results.











=cut

