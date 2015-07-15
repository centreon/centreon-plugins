
package Paws::ImportExport::ListJobsOutput {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Jobs => (is => 'ro', isa => 'ArrayRef[Paws::ImportExport::Job]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ImportExport::ListJobsOutput

=head1 ATTRIBUTES

=head2 IsTruncated => Bool

  
=head2 Jobs => ArrayRef[Paws::ImportExport::Job]

  


=cut

