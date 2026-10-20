% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function fig = plot_result(env, res, cfg, fname)
%PLOT_RESULT  Environment + planned paths + executed trajectory.

if nargin < 4, fname = ''; end

fig = figure('Color', 'w', 'Position', [80 80 1050 720]);
ax = axes(fig);
plot_environment(env, ax);

h1 = []; h2 = [];
if isfield(res, 'apath') && ~isempty(res.apath)
    h1 = plot(ax, res.apath.P(1,:), res.apath.P(2,:), 'b-', 'LineWidth', 1.6);
end
if isfield(res, 'rpath') && ~isempty(res.rpath)
    h2 = plot(ax, res.rpath.P(1,:), res.rpath.P(2,:), 'r-', 'LineWidth', 1.6);
end

tr = res.traj;
h3 = plot(ax, tr(1,:), tr(2,:), 'c-', 'LineWidth', 2.0);
h4 = plot(ax, res.start(1), res.start(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
h5 = [];
if ~isempty(res.stage)
    h5 = plot(ax, res.stage(1), res.stage(2), 'mp', 'MarkerSize', 12, 'MarkerFaceColor', 'm');
end

hCar = create_virtual_car(ax, res.final_pose, cfg.veh);
h6 = hCar.body;

handles = [h1 h2 h3 h4 h5 h6];
labels  = {'approach', 'planned reverse', 'executed', 'start', 'staging', 'final car'};
legend(ax, handles, labels, 'Location', 'northoutside', 'Orientation', 'horizontal');
title(ax, sprintf('%s | success=%d | pos=%.3f m | head=%.2f deg | t=%.1f s', ...
    res.msg, res.success, res.pos_err, rad2deg(res.head_err), res.time));

if ~isempty(fname)
    exportgraphics(fig, fname, 'Resolution', 130);
end
end
