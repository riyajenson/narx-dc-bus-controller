classdef PiExpertSystem < matlab.System
    %PIEXPERTSYSTEM Reference PI with saturation and anti-windup.

    properties (Nontunable)
        Kp = 0.65
        Ki = 2.5
        SampleTime = 0.01
        LowerLimit = -10
        UpperLimit = 10
    end

    properties (Access = private)
        IntegralState = 0
    end

    methods (Access = protected)
        function command = stepImpl(obj, reference, sensed)
            errorSignal = reference - sensed;
            candidateIntegral = obj.IntegralState + ...
                obj.SampleTime * errorSignal;
            unsaturated = obj.Kp * errorSignal + obj.Ki * candidateIntegral;
            command = min(max(unsaturated, obj.LowerLimit), obj.UpperLimit);
            if command == unsaturated || ...
                    (command == obj.UpperLimit && errorSignal < 0) || ...
                    (command == obj.LowerLimit && errorSignal > 0)
                obj.IntegralState = candidateIntegral;
            end
        end

        function resetImpl(obj)
            obj.IntegralState = 0;
        end
    end
end
