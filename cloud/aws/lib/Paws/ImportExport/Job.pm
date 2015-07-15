package Paws::ImportExport::Job {
  use Moose;
  has CreationDate => (is => 'ro', isa => 'Str');
  has IsCanceled => (is => 'ro', isa => 'Bool');
  has JobId => (is => 'ro', isa => 'Str');
  has JobType => (is => 'ro', isa => 'Str');
}
1;
