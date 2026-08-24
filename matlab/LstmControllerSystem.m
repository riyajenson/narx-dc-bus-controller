classdef LstmControllerSystem < matlab.System
    %LSTMCONTROLLERSYSTEM Stateful LSTM wrapper for normal Simulink simulation.

    properties (Access = private)
        Network
        InputMean
        InputStd
        TargetMean
        TargetStd
        LowerLimit
        UpperLimit
    end

    methods (Access = protected)
        function setupImpl(obj)
            cfg = project_config();
            modelFile = fullfile(cfg.rootDir, "models", ...
                "synthetic_lstm_controller.mat");
            trained = load(modelFile, "syntheticLstmNet", ...
                "normalization", "modelMetadata");
            obj.Network = resetState(trained.syntheticLstmNet);
            obj.InputMean = trained.normalization.inputMean;
            obj.InputStd = trained.normalization.inputStd;
            obj.TargetMean = trained.normalization.targetMean;
            obj.TargetStd = trained.normalization.targetStd;
            obj.LowerLimit = trained.modelMetadata.outputLimits(1);
            obj.UpperLimit = trained.modelMetadata.outputLimits(2);
        end

        function command = stepImpl(obj, reference, sensed)
            errorSignal = reference - sensed;
            rawInput = [reference; sensed; errorSignal];
            normalizedInput = (rawInput - obj.InputMean) ./ obj.InputStd;
            [obj.Network, normalizedOutput] = predictAndUpdateState( ...
                obj.Network, normalizedInput, "ExecutionEnvironment", "cpu");
            command = double(normalizedOutput) * obj.TargetStd + obj.TargetMean;
            command = min(max(command, obj.LowerLimit), obj.UpperLimit);
        end

        function resetImpl(obj)
            obj.Network = resetState(obj.Network);
        end

        function size = getOutputSizeImpl(~)
            size = [1 1];
        end

        function type = getOutputDataTypeImpl(~)
            type = "double";
        end

        function complex = isOutputComplexImpl(~)
            complex = false;
        end

        function fixed = isOutputFixedSizeImpl(~)
            fixed = true;
        end
    end
end
