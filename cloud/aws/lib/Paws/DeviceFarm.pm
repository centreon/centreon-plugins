package Paws::DeviceFarm {
  use Moose;
  sub service { 'devicefarm' }
  sub version { '2015-06-23' }
  sub target_prefix { 'DeviceFarm_20150623' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateDevicePool {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::CreateDevicePool', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateProject {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::CreateProject', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateUpload {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::CreateUpload', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetDevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDevicePool {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetDevicePool', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDevicePoolCompatibility {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetDevicePoolCompatibility', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetProject {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetProject', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetRun {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetRun', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetSuite {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetSuite', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetTest {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetTest', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetUpload {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::GetUpload', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListArtifacts {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListArtifacts', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDevicePools {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListDevicePools', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDevices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListDevices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListJobs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListJobs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListProjects {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListProjects', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListRuns {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListRuns', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSamples {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListSamples', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSuites {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListSuites', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTests {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListTests', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListUniqueProblems {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListUniqueProblems', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListUploads {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ListUploads', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ScheduleRun {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::DeviceFarm::ScheduleRun', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm - Perl Interface to AWS AWS Device Farm

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('DeviceFarm')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS Device Farm is a service that enables mobile app developers to test
Android and Fire OS apps on physical phones, tablets, and other devices
in the cloud.










=head1 METHODS

=head2 CreateDevicePool(name => Str, projectArn => Str, rules => ArrayRef[Paws::DeviceFarm::Rule], [description => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::CreateDevicePool>

Returns: a L<Paws::DeviceFarm::CreateDevicePoolResult> instance

  

Creates a device pool.











=head2 CreateProject(name => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::CreateProject>

Returns: a L<Paws::DeviceFarm::CreateProjectResult> instance

  

Creates a new project.











=head2 CreateUpload(name => Str, projectArn => Str, type => Str, [contentType => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::CreateUpload>

Returns: a L<Paws::DeviceFarm::CreateUploadResult> instance

  

Uploads an app or test scripts.











=head2 GetDevice(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetDevice>

Returns: a L<Paws::DeviceFarm::GetDeviceResult> instance

  

Gets information about a unique device type.











=head2 GetDevicePool(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetDevicePool>

Returns: a L<Paws::DeviceFarm::GetDevicePoolResult> instance

  

Gets information about a device pool.











=head2 GetDevicePoolCompatibility(appArn => Str, devicePoolArn => Str, [testType => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::GetDevicePoolCompatibility>

Returns: a L<Paws::DeviceFarm::GetDevicePoolCompatibilityResult> instance

  

Gets information about compatibility with a device pool.











=head2 GetJob(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetJob>

Returns: a L<Paws::DeviceFarm::GetJobResult> instance

  

Gets information about a job.











=head2 GetProject(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetProject>

Returns: a L<Paws::DeviceFarm::GetProjectResult> instance

  

Gets information about a project.











=head2 GetRun(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetRun>

Returns: a L<Paws::DeviceFarm::GetRunResult> instance

  

Gets information about a run.











=head2 GetSuite(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetSuite>

Returns: a L<Paws::DeviceFarm::GetSuiteResult> instance

  

Gets information about a suite.











=head2 GetTest(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetTest>

Returns: a L<Paws::DeviceFarm::GetTestResult> instance

  

Gets information about a test.











=head2 GetUpload(arn => Str)

Each argument is described in detail in: L<Paws::DeviceFarm::GetUpload>

Returns: a L<Paws::DeviceFarm::GetUploadResult> instance

  

Gets information about an upload.











=head2 ListArtifacts(arn => Str, type => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListArtifacts>

Returns: a L<Paws::DeviceFarm::ListArtifactsResult> instance

  

Gets information about artifacts.











=head2 ListDevicePools(arn => Str, [nextToken => Str, type => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListDevicePools>

Returns: a L<Paws::DeviceFarm::ListDevicePoolsResult> instance

  

Gets information about device pools.











=head2 ListDevices([arn => Str, nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListDevices>

Returns: a L<Paws::DeviceFarm::ListDevicesResult> instance

  

Gets information about unique device types.











=head2 ListJobs(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListJobs>

Returns: a L<Paws::DeviceFarm::ListJobsResult> instance

  

Gets information about jobs.











=head2 ListProjects([arn => Str, nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListProjects>

Returns: a L<Paws::DeviceFarm::ListProjectsResult> instance

  

Gets information about projects.











=head2 ListRuns(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListRuns>

Returns: a L<Paws::DeviceFarm::ListRunsResult> instance

  

Gets information about runs.











=head2 ListSamples(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListSamples>

Returns: a L<Paws::DeviceFarm::ListSamplesResult> instance

  

Gets information about samples.











=head2 ListSuites(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListSuites>

Returns: a L<Paws::DeviceFarm::ListSuitesResult> instance

  

Gets information about suites.











=head2 ListTests(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListTests>

Returns: a L<Paws::DeviceFarm::ListTestsResult> instance

  

Gets information about tests.











=head2 ListUniqueProblems(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListUniqueProblems>

Returns: a L<Paws::DeviceFarm::ListUniqueProblemsResult> instance

  

Gets information about unique problems.











=head2 ListUploads(arn => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ListUploads>

Returns: a L<Paws::DeviceFarm::ListUploadsResult> instance

  

Gets information about uploads.











=head2 ScheduleRun(appArn => Str, devicePoolArn => Str, projectArn => Str, test => Paws::DeviceFarm::ScheduleRunTest, [configuration => Paws::DeviceFarm::ScheduleRunConfiguration, name => Str])

Each argument is described in detail in: L<Paws::DeviceFarm::ScheduleRun>

Returns: a L<Paws::DeviceFarm::ScheduleRunResult> instance

  

Schedules a run.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

