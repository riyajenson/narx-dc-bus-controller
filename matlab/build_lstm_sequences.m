function [sequences, responses, ranges] = build_lstm_sequences( ...
        piInput, sensed, piOutput, sequenceLength)
%BUILD_LSTM_SEQUENCES Create non-overlapping chronological sequences.

piInput = double(piInput(:));
sensed = double(sensed(:));
piOutput = double(piOutput(:));
assert(numel(piInput) == numel(sensed) && numel(sensed) == numel(piOutput), ...
    "Controller signals must have equal lengths.");

sequenceCount = floor(numel(piInput) / sequenceLength);
assert(sequenceCount >= 10, "Not enough data for chronological sequences.");
sequences = cell(sequenceCount, 1);
responses = cell(sequenceCount, 1);
ranges = zeros(sequenceCount, 2);

for sequenceIndex = 1:sequenceCount
    first = (sequenceIndex - 1) * sequenceLength + 1;
    last = first + sequenceLength - 1;
    sequences{sequenceIndex} = [piInput(first:last).'; sensed(first:last).'];
    responses{sequenceIndex} = piOutput(first:last).';
    ranges(sequenceIndex, :) = [first, last];
end
end
