
package Paws::EC2::ImportImageResult {
  use Moose;
  has Architecture => (is => 'ro', isa => 'Str', xmlname => 'architecture', traits => ['Unwrapped',]);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped',]);
  has Hypervisor => (is => 'ro', isa => 'Str', xmlname => 'hypervisor', traits => ['Unwrapped',]);
  has ImageId => (is => 'ro', isa => 'Str', xmlname => 'imageId', traits => ['Unwrapped',]);
  has ImportTaskId => (is => 'ro', isa => 'Str', xmlname => 'importTaskId', traits => ['Unwrapped',]);
  has LicenseType => (is => 'ro', isa => 'Str', xmlname => 'licenseType', traits => ['Unwrapped',]);
  has Platform => (is => 'ro', isa => 'Str', xmlname => 'platform', traits => ['Unwrapped',]);
  has Progress => (is => 'ro', isa => 'Str', xmlname => 'progress', traits => ['Unwrapped',]);
  has SnapshotDetails => (is => 'ro', isa => 'ArrayRef[Paws::EC2::SnapshotDetail]', xmlname => 'snapshotDetailSet', traits => ['Unwrapped',]);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ImportImageResult

=head1 ATTRIBUTES

=head2 Architecture => Str

  

The architecture of the virtual machine.









=head2 Description => Str

  

A description of the import task.









=head2 Hypervisor => Str

  

The target hypervisor of the import task.









=head2 ImageId => Str

  

The ID of the Amazon Machine Image (AMI) created by the import task.









=head2 ImportTaskId => Str

  

The task ID of the import image task.









=head2 LicenseType => Str

  

The license type of the virtual machine.









=head2 Platform => Str

  

The operating system of the virtual machine.









=head2 Progress => Str

  

The progress of the task.









=head2 SnapshotDetails => ArrayRef[Paws::EC2::SnapshotDetail]

  

Information about the snapshots.









=head2 Status => Str

  

A brief status of the task.









=head2 StatusMessage => Str

  

A detailed status message of the import task.











=cut

