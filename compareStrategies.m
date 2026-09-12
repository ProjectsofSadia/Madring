function S = compareStrategies(sig, p)
%COMPARESTRATEGIES  Strategy A (maximum feasible regen) vs
%Strategy B (constraint-aware regen that backs off near a full store).
%
%At MADRING the two are expected to coincide, because the store never fills.
%That equivalence IS the result - do not force a difference.

    t = sig.time; n = numel(t); dt = [diff(t); 0];
    for s = 1:2
        soc = 0.5*p.ES_usable; E = 0; tFull = 0; tEmpty = 0; socTrace = zeros(n,1);
        for i = 1:n-1
            if dt(i) <= 0, socTrace(i) = soc; continue; end
            Pr = min(sig.P_rear(i), p.P_max_ERSK);
            if s == 2   % Strategy B: taper regen in the top 10% of the store
                head = (p.ES_usable - soc)/p.ES_usable;
                if head < 0.10, Pr = Pr * max(head/0.10, 0); end
            end
            e = Pr*dt(i);
            room = p.ES_usable - soc;
            if e > room, tFull = tFull + dt(i); e = room; end
            soc = soc + e; E = E + e;
            dep = sig.P_deploy(i)*dt(i);
            if dep > soc, tEmpty = tEmpty + dt(i); dep = soc; end
            soc = soc - dep;
            socTrace(i) = soc;
        end
        socTrace(n) = soc;
        S(s).name     = sprintf('Strategy %c', 'A'+s-1); %#ok<AGROW>
        S(s).E_total  = E;
        S(s).t_full   = tFull;
        S(s).t_empty  = tEmpty;
        S(s).soc      = socTrace;
    end
    fprintf('\n%-12s %12s %12s %12s\n','','harvest MJ','store FULL s','store EMPTY s');
    for s = 1:2
        fprintf('%-12s %12.3f %12.2f %12.2f\n', S(s).name, S(s).E_total/1e6, S(s).t_full, S(s).t_empty);
    end
end
