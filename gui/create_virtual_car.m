% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function h = create_virtual_car(ax, pose, veh, color)
%CREATE_VIRTUAL_CAR  Draw a car-shaped patch group in world coordinates.
%
%   h = create_virtual_car(ax, pose, veh, color)
%
%   The body, roof, windows, lights and wheels are parented to one
%   hgtransform, so the whole car can be moved/rotated by updating a single
%   matrix.  Front wheels have their own nested transforms for steering.

if nargin < 4 || isempty(color)
    color = [0.12 0.45 0.85];
end

L   = veh.wheelbase + veh.front_overhang;
x0  = -veh.rear_overhang;
x1  =  veh.wheelbase + veh.front_overhang;
hw  = veh.width / 2;
c   = 0.22;

h.group = hgtransform('Parent', ax);

% Chamfered body outline (body frame, rear axle at the origin).
body = [x0+c, -hw;
        x1-c, -hw;
        x1,   -hw+c;
        x1,    hw-c;
        x1-c,  hw;
        x0+c,  hw;
        x0,    hw-c;
        x0,   -hw+c];
h.body = patch('Parent', h.group, 'XData', body(:,1), 'YData', body(:,2), ...
    'FaceColor', color, 'EdgeColor', [0.04 0.10 0.20], 'LineWidth', 1.1, ...
    'PickableParts', 'none');

% Roof / cabin.
roof = [0.35, -0.62;
        2.15, -0.56;
        2.55, -0.36;
        2.55,  0.36;
        2.15,  0.56;
        0.35,  0.62];
h.roof = patch('Parent', h.group, 'XData', roof(:,1), 'YData', roof(:,2), ...
    'FaceColor', [0.60 0.78 0.96], 'EdgeColor', [0.20 0.32 0.45], ...
    'LineWidth', 0.8, 'PickableParts', 'none');

% Windshield / rear window.
ws = [2.15, -0.56; 2.55, -0.36; 2.55, 0.36; 2.15, 0.56];
h.windshield = patch('Parent', h.group, 'XData', ws(:,1), 'YData', ws(:,2), ...
    'FaceColor', [0.10 0.18 0.28], 'EdgeColor', 'none', 'PickableParts', 'none');

rw = [0.35, -0.62; 0.75, -0.56; 0.75, 0.56; 0.35, 0.62];
h.rearwindow = patch('Parent', h.group, 'XData', rw(:,1), 'YData', rw(:,2), ...
    'FaceColor', [0.10 0.18 0.28], 'EdgeColor', 'none', 'PickableParts', 'none');

% Headlights and tail lights.
hl = [x1-0.10, -0.62; x1, -0.62; x1, -0.36; x1-0.10, -0.36];
hr = [x1-0.10,  0.36; x1,  0.36; x1,  0.62; x1-0.10,  0.62];
tl = [x0, -0.62; x0+0.08, -0.62; x0+0.08, -0.36; x0, -0.36];
tr = [x0,  0.36; x0+0.08,  0.36; x0+0.08,  0.62; x0,  0.62];
h.headL = patch('Parent', h.group, 'XData', hl(:,1), 'YData', hl(:,2), ...
    'FaceColor', [1.0 0.92 0.45], 'EdgeColor', 'none', 'PickableParts', 'none');
h.headR = patch('Parent', h.group, 'XData', hr(:,1), 'YData', hr(:,2), ...
    'FaceColor', [1.0 0.92 0.45], 'EdgeColor', 'none', 'PickableParts', 'none');
h.tailL = patch('Parent', h.group, 'XData', tl(:,1), 'YData', tl(:,2), ...
    'FaceColor', [0.90 0.12 0.12], 'EdgeColor', 'none', 'PickableParts', 'none');
h.tailR = patch('Parent', h.group, 'XData', tr(:,1), 'YData', tr(:,2), ...
    'FaceColor', [0.90 0.12 0.12], 'EdgeColor', 'none', 'PickableParts', 'none');

% Wheels.  Rear wheels are fixed in the body frame; front wheels are nested
% transforms so they can show the steering angle.
wheelL = 0.55;
wheelW = 0.22;
wy = hw - 0.12;

wx = [-wheelL/2, -wheelW/2; wheelL/2, -wheelW/2; ...
       wheelL/2,  wheelW/2; -wheelL/2,  wheelW/2];

h.rearL = patch('Parent', h.group, ...
    'XData', wx(:,1), 'YData', wx(:,2) + wy, ...
    'FaceColor', [0.06 0.06 0.06], 'EdgeColor', 'none', 'PickableParts', 'none');
h.rearR = patch('Parent', h.group, ...
    'XData', wx(:,1), 'YData', wx(:,2) - wy, ...
    'FaceColor', [0.06 0.06 0.06], 'EdgeColor', 'none', 'PickableParts', 'none');

h.flGroup = hgtransform('Parent', h.group);
h.frGroup = hgtransform('Parent', h.group);
h.frontL = patch('Parent', h.flGroup, 'XData', wx(:,1), 'YData', wx(:,2), ...
    'FaceColor', [0.06 0.06 0.06], 'EdgeColor', 'none', 'PickableParts', 'none');
h.frontR = patch('Parent', h.frGroup, 'XData', wx(:,1), 'YData', wx(:,2), ...
    'FaceColor', [0.06 0.06 0.06], 'EdgeColor', 'none', 'PickableParts', 'none');

h.wheelbase = veh.wheelbase;
h.wheel_y   = wy;

h = update_virtual_car(h, pose, veh);
end
