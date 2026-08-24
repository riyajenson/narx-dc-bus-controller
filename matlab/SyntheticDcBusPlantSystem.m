classdef SyntheticDcBusPlantSystem < matlab.System
    %SYNTHETICDCBUSPLANTSYSTEM Discrete first-order educational DC-bus plant.

    properties (Nontunable)
        Tau = 0.35
        ControlGain = 2.5
        SampleTime = 0.01
        NominalVoltage = 300
        InitialVoltage = 298
    end

    properties (Access = private)
        Voltage
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.Voltage = obj.InitialVoltage;
        end

        function voltage = stepImpl(obj, delayedControl, loadDrop)
            derivative = ((obj.NominalVoltage - obj.Voltage) + ...
                obj.ControlGain * delayedControl - loadDrop) / obj.Tau;
            obj.Voltage = obj.Voltage + obj.SampleTime * derivative;
            voltage = obj.Voltage;
        end

        function resetImpl(obj)
            obj.Voltage = obj.InitialVoltage;
        end
    end
end
