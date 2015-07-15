package Paws::OpsWorks::WeeklyAutoScalingSchedule {
  use Moose;
  has Friday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Monday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Saturday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Sunday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Thursday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Tuesday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
  has Wednesday => (is => 'ro', isa => 'Paws::OpsWorks::DailyAutoScalingSchedule');
}
1;
