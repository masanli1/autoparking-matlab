% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function animate_result(env, res, cfg)
%ANIMATE_RESULT  Play back a completed parking manoeuvre.
%
%   Intended for interactive use (parking_main('mode','demo','animate',true)).
%   It is not used by the Monte Carlo batch.

fig = figure('Color', 'w', 'Position', [80 80 1050 720]);
ax  = axes(fig);
plot_environment(env, ax);

if isfield(res, 'apath') && ~isempty(res.apath)
    plot(ax, res.apath.P(1,:), res.apath.P(2,:), 'b-', 'LineWidth', 1.2);
end
if isfield(res, 'rpath') && ~isempty(res.rpath)
    plot(ax, res.rpath.P(1,:), res.rpath.P(2,:), 'r--', 'LineWidth', 1.2);
end

tr = res.traj;
hTrail = plot(ax, tr(1,1), tr(2,1), 'c-', 'LineWidth', 2.0);
hCar = create_virtual_car(ax, tr(:,1), cfg.veh);
title(ax, sprintf('%s | pos=%.3f m | head=%.2f deg', ...
    res.msg, res.pos_err, rad2deg(res.head_err)));

step = max(1, round(size(tr, 2) / 350));   % cap at ~350 frames
for k = 1:step:size(tr, 2)
    hCar = update_virtual_car(hCar, tr(:,k), cfg.veh);
    set(hTrail, 'XData', tr(1,1:k), 'YData', tr(2,1:k));
    drawnow limitrate;
    pause(0.008);
end
end
