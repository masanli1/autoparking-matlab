% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function corners = vehicle_footprint(pose, veh)
%VEHICLE_FOOTPRINT  Four body corners in world coordinates.
%
%   corners = vehicle_footprint([x;y;theta;delta], veh)
%   returns a 4x2 array ordered rear-left, front-left, front-right,
%   rear-right (counter-clockwise).

ro = veh.rear_overhang;
fo = veh.front_overhang;
L  = veh.wheelbase;
hw = veh.width / 2;

local = [-ro,    -hw;
          L+fo,  -hw;
          L+fo,   hw;
         -ro,     hw];

c = cos(pose(3));
s = sin(pose(3));
R = [c, -s; s, c];

corners = (R * local' + pose(1:2))';
end
