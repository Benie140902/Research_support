rng("default");
numFrameSimulation = 10;
networkSimulator = wirelessNetworkSimulator.init;
phyAbstractionType = "linkToSystemMapping";
csi_RS_Measuresignal = "CSI-RS";

% Operating frequency based duplexing selection in accordance to 3GPP
fc = input("Enter the desired frequency band for carrier frequency: ");
% Selecting Channel scenarios 
channelModel=input("Enter the desired scenario to evaluate gNB Performance :",'s');
% Selecting number of users
numUsers=input("Enter nnnumber of users connected to the network : ");

%  Entering desired duplexing mode
if(fc == 2.3e9) % n30 band
    duplexing = "FDD";
elseif(fc == 3.5e9) % n78 band
    duplexing = "TDD";
end

% Entering desired channel model scenario
    if(strcmp(channelModel,"UMa"))
        gNodeBPosition=[0 0 25];
        %  define users positions
        latitude=[35,100];
        longitude=[35,100];
        altitude=1.5;
        if(duplexing =="TDD")
        gNB_ant_config=[32 32];
        scs=input("Enter vaild scs for TDD : ");
        bandwidth=input("Enter valid bandwidth for correspondign scs : ")
    elseif(duplexing=="FDD")
        gNB_ant_config=[16 16];
        scs=input("Enter vaild scs for FDD : ");
        bandwidth=input("Enter valid bandwidth for correspondign scs : ");
        end
    %     numUsers=input("Enter the desired number of users : ");
    %     uePositions = [
    % latitude(1) + (latitude(2) - latitude(1)) * rand(numUsers, 1), ...
    % longitude(1) + (longitude(2) - longitude(1)) * rand(numUsers, 1), ...
    % altitude* ones(numUsers,1)];
    ueNames = "UE-" + (1:size(uePositions,1));
    elseif(channelModel=="RMa")
        gNodeBPosition=[0 0 35];
 %  define users positions
         latitude=[35,1000];
        longitude=[35,1000];
        altitude=1.5;

        if(duplexing =="TDD")
        gNB_ant_config=[32 32];
        scs=input("Enter vaild scs for TDD : ");
        bandwidth=input("Enter valid bandwidth for correspondign scs : ");

    elseif(duplexing=="FDD")
        gNB_ant_config=[16 16];
        scs=input("Enter vaild scs for FDD : ");
        bandwidth=input("Enter valid bandwidth for correspondign scs : ");
        end
        % numUsers=input("Enter the desired number of users : ");
        ueNames = "UE-" + (1:size(uePositions,1));
    end
% gNodeB parameters configuration
gNB = nrGNB(Position=gNodeBPosition, CarrierFrequency=fc, ChannelBandwidth=bandwidth, ...
    SubcarrierSpacing=scs, DuplexMode=duplexing, NumTransmitAntennas=gNB_ant_config(1), ...
    NumReceiveAntennas=gNB_ant_config(2), ReceiveGain=11, PHYAbstractionMethod=phyAbstractionType);
configureScheduler(gNB, CSIMeasurementSignalDL=csi_RS_Measuresignal); 

%  Define number of users and thier positions
% numUsers=input("Enter the desired number of users : ");
% uePositions = [
%     latitude(1) + (latitude(2) - latitude(1)) * rand(numUsers, 1), ...
%     longitude(1) + (longitude(2) - longitude(1)) * rand(numUsers, 1), ...
%     altitude* ones(numUsers,1)];
% ueNames = "UE-" + (1:size(uePositions,1));

UEs = nrUE(Name=ueNames, Position=uePositions, NumTransmitAntennas=4, ...
    NumReceiveAntennas=4, ReceiveGain=11, PHYAbstractionMethod=phyAbstractionType);

% rlcBearer = nrRLCBearerConfig(SNFieldLength=6, BucketSizeDuration=10);

    rlcBearer = nrRLCBearerConfig(SNFieldLength=6, BucketSizeDuration=10);
    connectUE(gNB, UEs, RLCBearerConfig=rlcBearer);
    appDataRate = 40e3;
    for ueIdx = 1:length(UEs)
    % Install the DL application traffic on gNB for the UE node
    dlApp = networkTrafficOnOff(GeneratePacket=true, OnTime=numFrameSimulation*10e-3, ...
        OffTime=0, DataRate=appDataRate);
    addTrafficSource(gNB, dlApp, DestinationNode=UEs(ueIdx));

    % Install the UL application traffic on the UE node for the gNB
    ulApp = networkTrafficOnOff(GeneratePacket=true, OnTime=numFrameSimulation*10e-3, ...
        OffTime=0, DataRate=appDataRate);
    addTrafficSource(UEs(ueIdx), ulApp);
    end

addNodes(networkSimulator, gNB);
addNodes(networkSimulator, UEs);

% Prompt for channel model
 % Define scenario boundaries
    pos = reshape([gNB.Position UEs.Position], 3, []);
    minX = min(pos(1, :));         
    minY = min(pos(2, :));          
    width = max(pos(1, :)) - minX; 
    height = max(pos(2, :)) - minY;
    if strcmp(channelModel,"RMa")
    channel = h38901Channel(Scenario="RMa",ScenarioExtents=[minX minY width height]);
    addChannelModel(networkSimulator,@channel.channelFunction);    
    connectNodes(channel, networkSimulator);
    elseif strcmp(channelModel,"UMa")
        channel = h38901Channel(Scenario="UMa",ScenarioExtents=[minX minY width height]);
       addChannelModel(networkSimulator,@channel.channelFunction);
       connectNodes(channel,networkSimulator);
    end;
disp('Channel configured and added to the network simulator.');
    enableTraces_partial_phy=true;
    if enableTraces_partial_phy
    % Create an object to log scheduler traces
    simSchedulingLogger_partial_phy = helperNRSchedulingLogger(numFrameSimulation, gNB, UEs);
    % Create an object to log for PHY traces
    simPhyLogger_partial_phy = helperNRPhyLogger(numFrameSimulation, gNB, UEs);
    end



numMetricPlotUpdates = 10;
metricsVisualizer = helperNRMetricsVisualizer(gNB, UEs, NumMetricsSteps=numMetricPlotUpdates, ...
    PlotSchedulerMetrics=true, PlotPhyMetrics=true);

% Generate simulation log file name based on input parameters
simulationLogFile = sprintf("simulationLogs_%s_%dMHZ_%dKHZ_%s_%d", duplexing, bandwidth/1e6, scs/1e3, channelModel, numUsers);

% Calculate the simulation duration (in seconds)
simulationTime = numFrameSimulation * 1e-2;
% Run the simulation
run(networkSimulator, simulationTime);

gNBStats = statistics(gNB);
ueStats = statistics(UEs);
displayPerformanceIndicators(metricsVisualizer);

if enableTraces_partial_phy
    simulationLogs = cell(1,1);
    if gNB.DuplexMode == "FDD"
        logInfo = struct(DLTimeStepLogs=[],ULTimeStepLogs=[],...
            SchedulingAssignmentLogs=[],PhyReceptionLogs=[]);
        [logInfo.DLTimeStepLogs,logInfo.ULTimeStepLogs] = getSchedulingLogs(simSchedulingLogger_partial_phy);
    else % TDD
        logInfo = struct(TimeStepLogs=[],SchedulingAssignmentLogs=[],PhyReceptionLogs=[]);
        logInfo.TimeStepLogs = getSchedulingLogs(simSchedulingLogger_partial_phy);
    end
    % Obtain the scheduling assignments log
    logInfo.SchedulingAssignmentLogs = getGrantLogs(simSchedulingLogger_partial_phy);
    % Obtain the Phy reception logs
    logInfo.PhyReceptionLogs = getReceptionLogs(simPhyLogger_partial_phy);
    % Save simulation logs in a MAT-file
    simulationLogs{1} = logInfo;
    desktopPath = "C:\Users\Benie Jaison\Desktop\Cell_Performance_study_4x8";
    filePath = fullfile(desktopPath, simulationLogFile + ".mat");
    save(filePath, "simulationLogs");
end