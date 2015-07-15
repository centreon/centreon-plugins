
package Paws::EC2::DescribeExportTasksResult {
  use Moose;
  has ExportTasks => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ExportTask]', xmlname => 'exportTaskSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeExportTasksResult

=head1 ATTRIBUTES

=head2 ExportTasks => ArrayRef[Paws::EC2::ExportTask]

  

Information about the export tasks.











=cut

