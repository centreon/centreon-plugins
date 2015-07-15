package Paws::ImportExport::Artifact {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has URL => (is => 'ro', isa => 'Str');
}
1;
