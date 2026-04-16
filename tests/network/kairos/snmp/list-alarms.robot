*** Settings ***
Documentation       network::kairos::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::kairos::snmp::plugin
...         --mode=list-alarms
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/kairos/snmp/kairos-ent


*** Test Cases ***
List-alarms ${tc}
    [Tags]    network    kairos    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_string}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_string
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List alarms: [name: IO1Contact][instance: 1] [name: Vocoder][instance: 10] [name: BsTemperature][instance: 11] [name: TxTemperature][instance: 12] [name: NoTxPower][instance: 13] [name: TxPowerLow][instance: 14] [name: TxPowerHigh][instance: 15] [name: SWRPower][instance: 16] [name: ROS][instance: 17] [name: TxPowerReduced][instance: 18] [name: SynchSource][instance: 19] [name: IO2Contact][instance: 2] [name: Synch][instance: 20] [name: BoardVTunes][instance: 21] [name: TrxVTunes][instance: 22] [name: BoardClock][instance: 23] [name: TrxClock][instance: 24] [name: BoardPllLock][instance: 25] [name: TrxPllLock][instance: 26] [name: PldFault][instance: 27] [name: PldDspComm][instance: 28] [name: IFRxGen][instance: 29] [name: LogicSupply][instance: 3] [name: RxGen][instance: 30] [name: RfNoise][instance: 31] [name: RegMaster][instance: 32] [name: RegSlave][instance: 33] [name: DeregSlave][instance: 34] [name: LossSlave][instance: 35] [name: MasterRole][instance: 36] [name: BckMasterConn][instance: 37] [name: DmrEmerCall][instance: 38] [name: 1Plus1BsActive][instance: 39] [name: SupplyHigh][instance: 4] [name: 1Plus1BsHotSpare][instance: 40] [name: TrxLayer][instance: 41] [name: BsLayer][instance: 42] [name: SipNameResolve][instance: 43] [name: FailSipReg][instance: 44] [name: SipReg][instance: 45] [name: SipDereg][instance: 46] [name: SipServerChange][instance: 47] [name: SipTrunk][instance: 48] [name: SupplyLow][instance: 5] [name: EthLink][instance: 6] [name: PldData][instance: 7] [name: DspUpAndRun][instance: 8] [name: Gnss][instance: 9]
