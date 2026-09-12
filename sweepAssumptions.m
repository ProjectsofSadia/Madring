function sweepAssumptions(T, p)
%SWEEPASSUMPTIONS  Does the ranking survive the assumed parameters?
    names = {'BASELINE','mass 768 kg','mass 850 kg','CdA 0.95','CdA 1.40', ...
             'rear frac 0.30','rear frac 0.50','eta 0.85','eta 0.95'};
    mods  = {struct(), struct('mass',768), struct('mass',850), ...
             struct('CdA',0.95), struct('CdA',1.40), ...
             struct('rear_frac',0.30), struct('rear_frac',0.50), ...
             struct('eta_regen',0.85), struct('eta_regen',0.95)};
    fprintf('\n%-18s %-34s %10s\n','scenario','top-3 by recoverable energy','lap MJ');
    fprintf('%s\n', repmat('-',1,66));
    for k = 1:numel(mods)
        q = p; f = fieldnames(mods{k});
        for i = 1:numel(f), q.(f{i}) = mods{k}.(f{i}); end
        ev = detectBrakingEvents(T, q, true);   % quiet
        [~, ev] = buildPowerSignals(T, ev, q);
        [~, ord] = sort([ev.E_recoverable], 'descend');
        lbl = arrayfun(@(e) sprintf('%.0fm', e.d_start), ev(ord(1:3)), 'uni', 0);
        fprintf('%-18s %-34s %10.3f\n', names{k}, strjoin(lbl,'  '), sum([ev.E_recoverable])/1e6);
    end
end
