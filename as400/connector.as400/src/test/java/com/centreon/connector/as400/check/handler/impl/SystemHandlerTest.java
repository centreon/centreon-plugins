package com.centreon.connector.as400.check.handler.impl;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.Vector;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.ArrayList;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.ProgramCall;
import com.ibm.as400.access.ProgramParameter;
import com.ibm.as400.access.SystemStatus;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

import org.junit.Test;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

public class SystemHandlerTest {

  private AtomicInteger runs = new AtomicInteger(0);

  @Test
  public void dumpAll_should_print_measures() throws Exception {
    ByteArrayOutputStream outContent = new ByteArrayOutputStream();
    PrintStream originalOut = System.out;
    System.setOut(new PrintStream(outContent));
    try {
      SystemStatus as400 = mock(SystemStatus.class);
      when(as400.getSystemPools()).thenReturn(new Vector<Object>().elements());
      SystemHandler sh = new SystemHandler(null, null, null, as400);
      sh.dumpSystem();
    } finally {
      System.setOut(originalOut);
    }
    assertEquals(DUMP_OUTPUT_EXPECTED, outContent.toString());
  }

  private final String DUMP_OUTPUT_EXPECTED = "ActiveJobsInSystem : 0\nActiveThreadsInSystem : 0\n"
      + "BatchJobsEndedWithPrinterOutputWaitingToPrint : 0\nBatchJobsEnding : 0\nBatchJobsHeldOnJobQueue : 0\n"
      + "BatchJobsHeldWhileRunning : 0\nBatchJobsOnAHeldJobQueue : 0\nBatchJobsOnUnassignedJobQueue : 0\nBatchJobsRunning : 0\n"
      + "BatchJobsWaitingForMessage : 0\nBatchJobsWaitingToRunOrAlreadyScheduled : 0\nCurrentProcessingCapacity : 0.0\n"
      + "CurrentUnprotectedStorageUsed : 0\nDateAndTimeStatusGathered : null\nElapsedTime : 0\nJobsInSystem : 0\nMainStorageSize : 0\n"
      + "MaximumJobsInSystem : 0\nMaximumUnprotectedStorageUsed : 0\nNumberOfPartitions : 0\nNumberOfProcessors : 0\nPartitionIdentifier : 0\n"
      + "PercentCurrentInteractivePerformance : 0.0\nPercentDBCapability : 0.0\nPercentPermanent256MBSegmentsUsed : 0.0\n"
      + "PercentPermanent4GBSegmentsUsed : 0.0\nPercentPermanentAddresses : 0.0\nPercentProcessingUnitUsed : 0.0\n"
      + "PercentSharedProcessorPoolUsed : 0.0\nPercentSystemASPUsed : 0.0\nPercentTemporary256MBSegmentsUsed : 0.0\n"
      + "PercentTemporary4GBSegmentsUsed : 0.0\nPercentTemporaryAddresses : 0.0\nPercentUncappedCPUCapacityUsed : 0.0\n"
      + "PoolsNumber : 0\nProcessorSharingAttribute : 0\nRestrictedStateFlag : false\nSystem : null\nSystemASP : 0 Mbytes\n"
      + "SystemName : null\nTotalAuxiliaryStorage : 0\nUsersCurrentSignedOn : 0\nUsersSignedOffWithPrinterOutputWaitingToPrint : 0\n"
      + "UsersSuspendedByGroupJobs : 0\nUsersSuspendedBySystemRequest : 0\nUsersTemporarilySignedOff : 0\n";

}
