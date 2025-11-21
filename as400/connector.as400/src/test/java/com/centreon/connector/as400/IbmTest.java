/////////////////////////////////////////////////////////////////////////
//
// Program call example.  This program calls the QWCRSSTS server program
// to retrieve the status of the system.
//
// Command syntax:
//    PCSystemStatusExample system
//
// This source is an example of IBM Toolbox for Java "ProgramCall".
//
/////////////////////////////////////////////////////////////////////////

package com.centreon.connector.as400;

import com.ibm.as400.access.*;

public class IbmTest extends Object {
  public static void main(String[] parameters) {
    System.out.println(" ");

    // if a system was not specified, display help text and exit.

    if (parameters.length >= 3) {

      try {
        // Create an AS400 object for the server that contains the
        // program. Assume the parameters are the system name, the login
        // and the password.

        AS400 as400 = new AS400(parameters[0], parameters[1], parameters[2]);

        // Create the path to the program.

        QSYSObjectPathName programName = new QSYSObjectPathName("QSYS", "QWCRSSTS", "PGM");

        // Create the program call object. Assocate the object with the
        // AS400 object that represents the server we get status from.

        ProgramCall getSystemStatus = new ProgramCall(as400);

        // Create the program parameter list. This program has five
        // parameters that will be added to this list.

        ProgramParameter[] parmlist = new ProgramParameter[5];

        // The server program returns data in parameter 1. It is an output
        // parameter. Allocate 64 bytes for this parameter.

        parmlist[0] = new ProgramParameter(64);

        // Parameter 2 is the buffer size of parm 1. It is a numeric input
        // parameter. Sets its value to 64, convert it to the server format,
        // then add the parm to the parm list.

        AS400Bin4 bin4 = new AS400Bin4();
        Integer iStatusLength = 64;
        byte[] statusLength = bin4.toBytes(iStatusLength);
        parmlist[1] = new ProgramParameter(statusLength);

        // Parameter 3 is the status-format parameter. It is a string input
        // parameter. Set the string value, convert it to the server format,
        // then add the parameter to the parm list.

        AS400Text text1 = new AS400Text(8, as400);
        byte[] statusFormat = text1.toBytes("SSTS0200");
        parmlist[2] = new ProgramParameter(statusFormat);

        // Parameter 4 is the reset-statistics parameter. It is a string input
        // parameter. Set the string value, convert it to the server format,
        // then add the parameter to the parm list.

        AS400Text text3 = new AS400Text(10, as400);
        byte[] resetStats = text3.toBytes("*NO       ");
        parmlist[3] = new ProgramParameter(resetStats);

        // Parameter 5 is the error info parameter. It is an input/output
        // parameter. Add it to the parm list.

        byte[] errorInfo = new byte[32];
        parmlist[4] = new ProgramParameter(errorInfo, 0);

        // Set the program to call and the parameter list to the program
        // call object.

        getSystemStatus.setProgram(programName.getPath(), parmlist);

        // Run the program then sleep. We run the program twice because
        // the first set of results are inflated. If we discard the first
        // set of results and run the command again five seconds later the
        // number will be more accurate.

        getSystemStatus.run();
        Thread.sleep(5000);

        // Run the program

        if (getSystemStatus.run() != true) {

          // If the program did not run get the list of error messages
          // from the program object and display the messages. The error
          // would be something like program-not-found or not-authorized
          // to the program.

          AS400Message[] msgList = getSystemStatus.getMessageList();

          System.out.println("The program did not run.  Server messages:");

          for (int i = 0; i < msgList.length; i++) {
            System.out.println(msgList[i].getText());
          }
        }

        // Else the program did run.

        else {

          // Create a server to Java numeric converter. This converter
          // will be used in the following section to convert the numeric
          // output from the server format to Java format.

          AS400Bin4 as400Int = new AS400Bin4();

          // Get the results of the program. Output data is in
          // a byte array in the first parameter.

          byte[] as400Data = parmlist[0].getOutputData();

          // CPU utilization is a numeric field starting at byte
          // 32 of the output buffer. Convert this number from the
          // server format to Java format and output the number.

          Integer cpuUtil = (Integer) as400Int.toObject(as400Data, 32);
          cpuUtil = cpuUtil.intValue() / 10;
          System.out.print("CPU Utilization:  ");
          System.out.print(cpuUtil);
          System.out.println("%");

          // DASD utilization is a numeric field starting at byte
          // 52 of the output buffer. Convert this number from the
          // server format to Java format and output the number.

          Integer dasdUtil = (Integer) as400Int.toObject(as400Data, 52);
          dasdUtil = dasdUtil.intValue() / 10000;
          System.out.print("Dasd Utilization: ");
          System.out.print(dasdUtil);
          System.out.println("%");

          // Number of jobs is a numeric field starting at byte
          // 36 of the output buffer. Convert this number from the
          // server format to Java format and output the number.

          Integer nj = (Integer) as400Int.toObject(as400Data, 36);
          System.out.print("Active jobs:      ");
          System.out.println(nj);

        }

        // This program is done running program so disconnect from
        // the command server on the server. Program call and command
        // call use the same server on the server.

        as400.disconnectService(AS400.COMMAND);
      } catch (Exception e) {
        // If any of the above operations failed say the program failed
        // and output the exception.

        System.out.println("Program call failed");
        System.out.println(e);
      }
    }

    // Display help text when parameters are incorrect.

    else {
      System.out.println("");
      System.out.println("");
      System.out.println("");
      System.out.println("Parameters are not correct.  Command syntax is:");
      System.out.println("");
      System.out.println("   PCSystemStatusExample myServer myLogin myPassword");
      System.out.println("");
      System.out.println("Where");
      System.out.println("");
      System.out.println("   myServer = get status of this server ");
      System.out.println("");
      System.out.println("For example:");
      System.out.println("");
      System.out.println("   PCSystemStatusExample mySystem myUser myUserPwd");
      System.out.println("");
      System.out.println("");
    }

    System.exit(0);
  }
}