
package Paws::RedShift::ResizeProgressMessage {
  use Moose;
  has AvgResizeRateInMegaBytesPerSecond => (is => 'ro', isa => 'Num');
  has ElapsedTimeInSeconds => (is => 'ro', isa => 'Int');
  has EstimatedTimeToCompletionInSeconds => (is => 'ro', isa => 'Int');
  has ImportTablesCompleted => (is => 'ro', isa => 'ArrayRef[Str]');
  has ImportTablesInProgress => (is => 'ro', isa => 'ArrayRef[Str]');
  has ImportTablesNotStarted => (is => 'ro', isa => 'ArrayRef[Str]');
  has ProgressInMegaBytes => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Str');
  has TargetClusterType => (is => 'ro', isa => 'Str');
  has TargetNodeType => (is => 'ro', isa => 'Str');
  has TargetNumberOfNodes => (is => 'ro', isa => 'Int');
  has TotalResizeDataInMegaBytes => (is => 'ro', isa => 'Int');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ResizeProgressMessage

=head1 ATTRIBUTES

=head2 AvgResizeRateInMegaBytesPerSecond => Num

  

The average rate of the resize operation over the last few minutes,
measured in megabytes per second. After the resize operation completes,
this value shows the average rate of the entire resize operation.









=head2 ElapsedTimeInSeconds => Int

  

The amount of seconds that have elapsed since the resize operation
began. After the resize operation completes, this value shows the total
actual time, in seconds, for the resize operation.









=head2 EstimatedTimeToCompletionInSeconds => Int

  

The estimated time remaining, in seconds, until the resize operation is
complete. This value is calculated based on the average resize rate and
the estimated amount of data remaining to be processed. Once the resize
operation is complete, this value will be 0.









=head2 ImportTablesCompleted => ArrayRef[Str]

  

The names of tables that have been completely imported .

Valid Values: List of table names.









=head2 ImportTablesInProgress => ArrayRef[Str]

  

The names of tables that are being currently imported.

Valid Values: List of table names.









=head2 ImportTablesNotStarted => ArrayRef[Str]

  

The names of tables that have not been yet imported.

Valid Values: List of table names









=head2 ProgressInMegaBytes => Int

  

While the resize operation is in progress, this value shows the current
amount of data, in megabytes, that has been processed so far. When the
resize operation is complete, this value shows the total amount of
data, in megabytes, on the cluster, which may be more or less than
TotalResizeDataInMegaBytes (the estimated total amount of data before
resize).









=head2 Status => Str

  

The status of the resize operation.

Valid Values: C<NONE> | C<IN_PROGRESS> | C<FAILED> | C<SUCCEEDED>









=head2 TargetClusterType => Str

  

The cluster type after the resize operation is complete.

Valid Values: C<multi-node> | C<single-node>









=head2 TargetNodeType => Str

  

The node type that the cluster will have after the resize operation is
complete.









=head2 TargetNumberOfNodes => Int

  

The number of nodes that the cluster will have after the resize
operation is complete.









=head2 TotalResizeDataInMegaBytes => Int

  

The estimated total amount of data, in megabytes, on the cluster before
the resize operation began.











=cut

