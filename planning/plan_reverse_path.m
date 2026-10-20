% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function out = plan_reverse_path(env, stage, R, cfg)
%PLAN_REVERSE_PATH  Quarter-circle + straight reverse path into the slot.
%
%   out = plan_reverse_path(env, stage, R, cfg)
%
%   Left approach (stage heading ~ 0):
%       centre C = [xs + R, ye], arc from the bottom of the circle to its
%       left-most point (clockwise), then straight along the slot centreline.
%
%   Right approach (stage heading ~ pi):
%       centre C = [xs - R, ye], arc from the bottom of the circle to its
%       right-most point (counter-clockwise), then straight.
%
%   In both cases the car ends with heading -pi/2 (nose towards the aisle),
%   i.e. a true reverse (back-in) parking manoeuvre.

out.ok   = false;
out.side = 0;
out.path = [];
out.msg  = '';

xs  = env.target.x_center;
ye  = env.target.y_entrance;
yf  = env.target.final_pose(2);

if yf <= ye + 0.5
    out.msg = 'slot is too shallow for reverse parking';
    return;
end

if abs(wrap_pi(stage(3))) <= pi/2
    side = 1;                                   % approach from the left
    C    = [xs + R; ye];
    phi  = linspace(-pi/2, -pi, max(40, ceil(R*pi/2/0.05)));
    P_arc  = C + R * [cos(phi); sin(phi)];
    th_arc = phi + pi/2;
    kap_arc = -1 / R;
else
    side = -1;                                  % approach from the right
    C    = [xs - R; ye];
    phi  = linspace(-pi/2, 0, max(40, ceil(R*pi/2/0.05)));
    P_arc  = C + R * [cos(phi); sin(phi)];
    th_arc = phi - pi/2;
    kap_arc = 1 / R;
end

th_arc = unwrap(th_arc);

% Straight reverse segment along the slot centreline.
ys = linspace(ye, yf, max(40, ceil((yf - ye) / 0.05)));
S  = [xs * ones(1, numel(ys)); ys];
T  = -pi/2 * ones(1, numel(ys));
K  = zeros(1, numel(ys));

% Drop the duplicated entrance point.
P     = [P_arc, S(:,2:end)];
theta = [th_arc, T(2:end)];
kappa = [kap_arc * ones(1, size(P_arc,2)), K(2:end)];

s = [0, cumsum(hypot(diff(P(1,:)), diff(P(2,:))))];
s(end) = max(s(end), 1e-6);

path.P     = P;
path.theta = theta;
path.s     = s;
path.kappa = kappa;
path.n     = numel(s);
path.ok    = true;

[ok, bad] = validate_path_collision(env, path);
if ~ok
    out.msg  = sprintf('reverse path collides at sample %d', bad);
    out.side = side;
    return;
end

out.ok   = true;
out.side = side;
out.path = path;
out.msg  = 'ok';
end
