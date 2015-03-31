classdef RawIOTestConfigurationProvider < TestConfigurationProvider
    % RawIOTestConfigurationProvider Provides a mask for raw IO input
    % testing.
    %
    % The default mask has a period of 10000 and an equally long readout
    % window. It can be changed via the constructor (optional).
    
    
    properties (GetAccess = protected)
        mask = struct( ...
            'begin',    0, ...
            'end',      10000, ...
            'period',   10000 ...
        );
        iterations = 1;
    end
    
    methods (Access = protected)
        
        function computePulseGroup(self)
            for i = 1:self.iterations
                self.pulseBuilder.addPulse(self.mask, 1);
            end
        end
        
    end
    
    methods (Access = public)
        
        function self = RawIOTestConfigurationProvider(inputChannel, pulseBuilder, mask, iterations)
            self = self@TestConfigurationProvider(inputChannel, pulseBuilder);
            if (nargin >= 3)
                assert(~isfield(mask, 'type') || ~strcmp(mask.type, 'Table Mask'), 'mask must not be a table mask!');
                assert(mask.begin == 0 && mask.end == mask.period, 'Readout window of mask must be equal to its period!');
                self.mask = mask;
            end
            if (nargin == 4)
                assert(isnumeric(iterations) && iterations > 0, 'iterations must be a positive integer value!');
                self.iterations = iterations;
            end
        end
    end
    
end

