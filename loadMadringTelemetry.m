function T = loadMadringTelemetry(csvFile)
%LOADMADRINGTELEMETRY  Read one lap of real MADRING telemetry.
%   Expects columns: time, distance, speed(km/h), throttle(%), brake(0/1),
%                    rpm, gear, drs, x, y, z
    if nargin < 1, csvFile = fullfile('..','data','madring_FP1_RUS_lap20.csv'); end
    assert(isfile(csvFile), 'Telemetry CSV not found: %s', csvFile);
    T = readtable(csvFile);
    req = {'time','distance','speed','throttle','brake'};
    missing = req(~ismember(req, T.Properties.VariableNames));
    assert(isempty(missing), 'Missing channels: %s', strjoin(missing,', '));
    T = sortrows(T,'time');
    fprintf('Loaded %d samples | lap %.3f s | distance %.1f m | speed %.0f-%.0f km/h\n', ...
        height(T), T.time(end)-T.time(1), max(T.distance), min(T.speed), max(T.speed));
end
