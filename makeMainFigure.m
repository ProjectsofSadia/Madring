function makeMainFigure(sig, ev, p, outPng)
%MAKEMAINFIGURE  One publication figure: speed, brake with top-3 highlighted,
%cumulative recoverable electrical energy.
    if nargin < 4, outPng = 'MADRING_regen_main.png'; end
    d = sig.distance/1000; t = sig.time;
    Pc = min(sig.P_rear, p.P_max_ERSK);
    cum = cumsum([0; Pc(1:end-1).*diff(t)]);

    [~, ord] = sort([ev.E_recoverable],'descend'); top3 = ord(1:min(3,numel(ev)));
    RED = [0.784 0.063 0.180]; BLU = [0.071 0.224 0.357]; GRY = [0.604 0.647 0.694];

    f = figure('Color','w','Position',[80 80 1400 1000]);
    tl = tiledlayout(f, 8, 1, 'TileSpacing','compact','Padding','compact');

    ax0 = nexttile(tl,1,[3 1]); hold(ax0,'on');
    ax1 = nexttile(tl,4,[1 1]); hold(ax1,'on');
    ax2 = nexttile(tl,5,[3 1]); hold(ax2,'on');

    for k = 1:numel(ev)
        isTop = any(k == top3);
        c = GRY; a = 0.10; if isTop, c = RED; a = 0.18; end
        for ax = [ax0 ax1 ax2]
            xr = [ev(k).d_start ev(k).d_end]/1000;
            patch(ax, [xr fliplr(xr)], [-1e4 -1e4 1e4 1e4], c, ...
                  'FaceAlpha',a, 'EdgeColor','none','HandleVisibility','off');
        end
    end

    plot(ax0, d, sig.speed, 'k', 'LineWidth',1.6);
    ylabel(ax0,'Speed (km/h)'); ylim(ax0,[0 340]); grid(ax0,'on'); xticklabels(ax0,{});
    title(ax0, {'Where Can a 2026 Hybrid Race Car Recover the Most Energy at MADRING?', ...
        'Real FP1 telemetry, 2026 Spanish GP - RUS lap 20, 94.077 s'}, ...
        'FontSize',14,'FontWeight','bold');
    for k = top3
        text(ax0, mean([ev(k).d_start ev(k).d_end])/1000, ev(k).v_min-55, ...
            sprintf('%.2f MJ', ev(k).E_recoverable/1e6), 'Color',RED, ...
            'FontWeight','bold','HorizontalAlignment','center','FontSize',11);
    end

    area(ax1, d, sig.brake, 'FaceColor',BLU,'FaceAlpha',0.9,'EdgeColor','none');
    ylabel(ax1,'Brake'); yticks(ax1,[0 1]); ylim(ax1,[-0.1 1.2]); grid(ax1,'on'); xticklabels(ax1,{});

    plot(ax2, d, cum/1e6, 'Color',RED,'LineWidth',2.4);
    yline(ax2, p.ES_usable/1e6, '--','Color',BLU,'LineWidth',1.5, ...
        'Label','Energy Store usable capacity - 4.0 MJ (FIA Art. C5.2.8)', ...
        'LabelHorizontalAlignment','left','FontSize',10);
    ylabel(ax2,{'Cumulative recoverable','electrical energy (MJ)'});
    xlabel(ax2,'Distance around lap (km)'); grid(ax2,'on'); ylim(ax2,[0 4.6]);
    text(ax2, d(end), cum(end)/1e6-0.4, sprintf('lap total\n%.2f MJ', cum(end)/1e6), ...
        'HorizontalAlignment','right','Color',RED,'FontWeight','bold','FontSize',11);

    for ax = [ax0 ax1 ax2], xlim(ax,[0 5.42]); end

    annotation(f,'textbox',[0.09 0.005 0.9 0.035],'EdgeColor','none','FontSize',10, ...
      'String',['Source telemetry: public FastF1 data   |   ' ...
                'Electrical recovery: simplified engineering model']);
    exportgraphics(f, outPng, 'Resolution', 200);
    fprintf('Figure written: %s\n', outPng);
end
