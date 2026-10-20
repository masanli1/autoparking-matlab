% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function h = update_virtual_car(h, pose, veh)
%UPDATE_VIRTUAL_CAR  Move/rotate an existing virtual-car graphics group.
%
%   h = update_virtual_car(h, [x;y;theta;delta], veh)

M = makehgtform('translate', [pose(1), pose(2), 0]) * ...
    makehgtform('zrotate', pose(3));
set(h.group, 'Matrix', M);

set(h.flGroup, 'Matrix', ...
    makehgtform('translate', [h.wheelbase,  h.wheel_y, 0]) * ...
    makehgtform('zrotate', pose(4)));
set(h.frGroup, 'Matrix', ...
    makehgtform('translate', [h.wheelbase, -h.wheel_y, 0]) * ...
    makehgtform('zrotate', pose(4)));
end
