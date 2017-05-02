classdef runningG2 < timeTaggerG2
    %This class will persist and build up a running G2 over many data files
    
    properties
        filenameList = {};
        shotsProcessed = 0;
    end
    
    methods
        %Constructor
        function obj = runningG2()
            %See if there is an existing runningG2 class on the base
            %workspace else do nothing
            try
                obj = evalin('base','runningG2obj');
            end
        end
        function loadFromFile(self,filename)
            loadFromFile@timeTaggerG2(self,filename);
            self.filenameList{end+1} = filename;
        end
        function updateAllPairwiseG2(self)
            for i=1:length(self.channelList)-1
                for j=i+1:length(self.channelList)
                    self.updateG2Test(self.channelList(i),self.channelList(j));
                end
            end
        end
        function updateAllPairwiseG2Test(self)
            for i=1:length(self.channelList)-1
                for j=i+1:length(self.channelList)
                    self.updateG2Test2(self.channelList(i),self.channelList(j));
                end
            end
        end
        function updateAllPairwiseG2WithoutCross(self)
            for i=1:length(self.channelList)-1
                for j=i+1:length(self.channelList)
                    self.updateG2WithoutCross(self.channelList(i),self.channelList(j));
                end
            end
        end
        function runFit(self)
            self.updateAllPairwiseG2();
            %Save runningG2 to base workspace
            assignin('base','runningG2obj',self);
            self.shotsProcessed = self.shotsProcessed + 1
        end
        function plotG2(self)
            [time,g2] = self.getFoldedG2();
            plot(time,g2);
            ylim([0,1.5])
            xlabel('\tau')
            ylabel('g^{(2)}(\tau)')
        end
    end
    
end

