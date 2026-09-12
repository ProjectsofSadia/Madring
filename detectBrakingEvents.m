function ev = detectBrakingEvents(T, p, quiet)
%DETECTBRAKINGEVENTS  Find braking events in real telemetry. No assumed corners.
    if nargin < 3, quiet = false; end
    t = T.time(:); d = T.distance(:); v = T.speed(:)/3.6; b = T.brake(:) > 0;
    n = numel(t);

    starts = []; stops = []; i = 1;
    while i <= n
        if b(i)
            j = i;
            while j < n
                look = min(n, j + p.bridge);
                if any(b(j+1:look)), j = find(b(j+1:look),1,'last') + j; else, break; end
            end
            starts(end+1) = i; stops(end+1) = j; %#ok<AGROW>
            i = j + 1;
        else
            i = i + 1;
        end
    end

    ev = struct('d_start',{},'d_end',{},'v_entry',{},'v_min',{},'dv',{}, ...
                'duration',{},'dKE',{},'i0',{},'i1',{});
    for k = 1:numel(starts)
        a = starts(k); bb = stops(k);
        lo = max(1, a-4);
        [vin, ri] = max(v(lo:a));  i0 = lo + ri - 1;
        hi = min(n, bb+6);
        [vmn, rj] = min(v(a:hi));  i1 = a + rj - 1;
        if (vin - vmn)*3.6 < p.dv_min_kmh, continue; end
        s.d_start  = d(i0);
        s.d_end    = d(i1);
        s.v_entry  = vin*3.6;
        s.v_min    = vmn*3.6;
        s.dv       = (vin - vmn)*3.6;
        s.duration = t(i1) - t(i0);
        s.dKE      = 0.5*p.mass*(vin^2 - vmn^2);   % THEORETICAL. Not recovered energy.
        s.i0 = i0; s.i1 = i1;
        ev(end+1) = s; %#ok<AGROW>
    end
    if ~quiet
        fprintf('Detected %d significant braking events (speed drop >= %d km/h)\n', ...
            numel(ev), p.dv_min_kmh);
    end
end
