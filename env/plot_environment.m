% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function ax = plot_environment(env, ax)
%PLOT_ENVIRONMENT  Top-down view of the garage and its slots.

if nargin < 2 || isempty(ax)
    figure('Color', 'w');
    ax = gca;
end

imagesc(ax, env.x, env.y, env.occ);
set(ax, 'YDir', 'normal');
axis(ax, 'equal');
axis(ax, 'tight');
colormap(ax, flipud(gray));
hold(ax, 'on');

% Slot outlines and numbers.
for i = 1:numel(env.slots.top)
    s = env.slots.top(i);
    rectangle(ax, 'Position', [s.x_center - s.width/2, s.y_entrance, s.width, s.depth], ...
        'EdgeColor', [0.45 0.45 0.45], 'LineStyle', '--', 'LineWidth', 0.8);
    text(ax, s.x_center, s.y_entrance + 0.35, sprintf('%d', i), ...
        'Color', [0.35 0.35 0.35], 'FontSize', 8, ...
        'HorizontalAlignment', 'center');
end

% Target slot.
t = env.target;
rectangle(ax, 'Position', [t.x_center - t.width/2, t.y_entrance, t.width, t.depth], ...
    'EdgeColor', [0.0 0.55 0.0], 'LineWidth', 2.2, ...
    'FaceColor', [0.20 0.85 0.20], 'FaceAlpha', 0.18);
plot(ax, t.final_pose(1), t.final_pose(2), 'g*', 'MarkerSize', 10, 'LineWidth', 1.5);

xlabel(ax, 'x [m]');
ylabel(ax, 'y [m]');
title(ax, 'Garage environment (top view)');
end
