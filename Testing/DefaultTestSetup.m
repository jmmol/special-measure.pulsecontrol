classdef DefaultTestSetup < TestSetup

    properties(GetAccess = protected, SetAccess = protected)
        pulsegroup;
        dac;
        vawg;
    end
    
    methods (Access = public)
        
        function obj = DefaultTestSetup()
            obj = obj@TestSetup();
            
            obj.duration = 1000000; %us
            obj.inputChannel = 1;
        end
        
        function initiate(self)
            % pulse to test
            self.initPulseGroup();

            % awg to test
            self.initVAWG();

            self.vawg.add(self.pulsegroup.name);
            self.vawg.setActivePulseGroup(self.pulsegroup.name);
            
            % DAQ card
            self.initDAC();

            self.vawg.arm();
        end
        
        function run(self)
            self.dac.issueTrigger();
    
            while self.vawg.playbackInProgress()
                pause(1);
                fprintf('Waiting for playback to finish...\n');
            end

            measuredData = self.dac.getResult(self.inputChannel);
            self.evaluate(measuredData);
        end
        
    end
    
    methods (Access = protected)    
        
        function initVAWG(self)
            self.vawg = VAWG();
    
            awg = PXDAC_DC('messrechnerDC',1);
            awg.setOutputVoltage(1,1);

            self.vawg.addAWG(awg);
            self.vawg.createVirtualChannel(awg,1,1);
        end
        
        function initDAC(self)
            self.dac = ATS9440(1);
    
            self.dac.samprate = 100e6; %samples per second
            sis = self.duration * self.dac.samprate / 1e6; % samples in scanline

            self.dac.useAsTriggerSource();
            
            self.dac.configureMeasurement(1, sis, 1, self.inputChannel);
        end
        
        function initPulseGroup(self)
            N = 1000;
            rng(42);

            pulse.data.pulsetab = zeros(2, N);
            pulse.data.pulsetab(1,:) = linspace(1, self.duration, N);
            pulse.data.pulsetab(2,:) = rand(1, N) * 2 - 1;

            pulse.name = 'hardwareTestPulse';

            self.pulsegroup.pulses = plsreg(pulse);
            self.pulsegroup.nrep = 1;
            self.pulsegroup.name = 'hardwareTestPulseGroup';
            self.pulsegroup.chan = 1;
            self.pulsegroup.ctrl = 'notrig';

            plsdefgrp(self.pulsegroup);
        end
        
    end
    
end
