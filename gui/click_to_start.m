% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function [start, ok, msg] = click_to_start(env, cfg, pt)
%CLICK_TO_START  Convert a click in the aisle into a feasible start pose.
%
%   [start, ok, msg] = click_to_start(env, cfg, pt)
%
%   pt = [x, y] in world metres.  The side is chosen from the click position
%   so that the reverse staging pose is ahead of the car; the pose is then
%   validated with the same planner and collision checks as the batch runs.

start = [];
ok    = false;
msg   = '';

x = pt(1);
y = pt(2);

% Keep the whole car inside the aisle.
if x < env.aisle(1) + 1.0 || x > env.aisle(2) - 1.0 || ...
   y < env.aisle(3) + 1.2 || y > env.aisle(4) - 1.2
    msg = '请点击车道内部（离边界至少约 1 m）';
    return;
end

xs = env.target.x_center;
R  = cfg.ctrl.reverse_radius;

% Staging positions: left approach -> xs+R, right approach -> xs-R.
can_left  = x < xs + R - 1.0;
can_right = x > xs - R + 1.0;

if can_left && (~can_right || x < xs)
    heading = 0;
elseif can_right
    heading = pi;
else
    msg = '该位置离 staging 位太近，请换一处点击';
    return;
end

S = [x; y; heading; 0];

if check_vehicle_collision(env, S, 'dense')
    msg = '该位置会与墙体或停放车辆重叠';
    return;
end

ap = plan_approach(env, S, cfg);
if ~ap.ok
    msg = ['该位置无法规划前进段：' ap.msg];
    return;
end

rp = plan_reverse_path(env, ap.stage, ap.R, cfg);
if ~rp.ok
    msg = ['该位置无法生成倒车路径：' rp.msg];
    return;
end

start = S;
ok    = true;
msg   = 'ok';
end
