package Paws::EC2::ExportTask {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has ExportTaskId => (is => 'ro', isa => 'Str', xmlname => 'exportTaskId', traits => ['Unwrapped']);
  has ExportToS3Task => (is => 'ro', isa => 'Paws::EC2::ExportToS3Task', xmlname => 'exportToS3', traits => ['Unwrapped']);
  has InstanceExportDetails => (is => 'ro', isa => 'Paws::EC2::InstanceExportDetails', xmlname => 'instanceExport', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
}
1;
