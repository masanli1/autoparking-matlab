% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function [ok, first_bad] = validate_path_collision(env, path)
%VALIDATE_PATH_COLLISION  Dense footprint check over every path pose.
%
%   [ok, first_bad] = validate_path_collision(env, path)

ok = true;
first_bad = 0;

for i = 1:path.n
    pose = [path.P(:,i); path.theta(i); 0];
    if check_vehicle_collision(env, pose, 'dense')
        ok = false;
        first_bad = i;
        return;
    end
end
end
