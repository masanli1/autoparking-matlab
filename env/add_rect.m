% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function env = add_rect(env, x0, y0, w, h)
%ADD_RECT  Mark an axis-aligned world rectangle as occupied.
%
%   env = add_rect(env, x0, y0, w, h)
%   (x0,y0) is the lower-left corner, w/h are width/height in metres.

res  = env.res;
xmin = env.xlim(1);
ymin = env.ylim(1);

c0 = max(1, round((x0 - xmin) / res) + 1);
c1 = min(env.nx, round((x0 + w - xmin) / res) + 1);
r0 = max(1, round((y0 - ymin) / res) + 1);
r1 = min(env.ny, round((y0 + h - ymin) / res) + 1);

if c1 >= c0 && r1 >= r0
    env.occ(r0:r1, c0:c1) = true;
end
end
