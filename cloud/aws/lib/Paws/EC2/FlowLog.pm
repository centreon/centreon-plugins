package Paws::EC2::FlowLog {
  use Moose;
  has CreationTime => (is => 'ro', isa => 'Str', xmlname => 'creationTime', traits => ['Unwrapped']);
  has DeliverLogsErrorMessage => (is => 'ro', isa => 'Str', xmlname => 'deliverLogsErrorMessage', traits => ['Unwrapped']);
  has DeliverLogsPermissionArn => (is => 'ro', isa => 'Str', xmlname => 'deliverLogsPermissionArn', traits => ['Unwrapped']);
  has DeliverLogsStatus => (is => 'ro', isa => 'Str', xmlname => 'deliverLogsStatus', traits => ['Unwrapped']);
  has FlowLogId => (is => 'ro', isa => 'Str', xmlname => 'flowLogId', traits => ['Unwrapped']);
  has FlowLogStatus => (is => 'ro', isa => 'Str', xmlname => 'flowLogStatus', traits => ['Unwrapped']);
  has LogGroupName => (is => 'ro', isa => 'Str', xmlname => 'logGroupName', traits => ['Unwrapped']);
  has ResourceId => (is => 'ro', isa => 'Str', xmlname => 'resourceId', traits => ['Unwrapped']);
  has TrafficType => (is => 'ro', isa => 'Str', xmlname => 'trafficType', traits => ['Unwrapped']);
}
1;
