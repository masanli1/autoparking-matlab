% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function cfg = default_config()
%DEFAULT_CONFIG  All tunable parameters for the parking simulator.
%
%   The model is a rear-axle bicycle model in world metres.  The environment
%   is a single-loaded garage: one row of perpendicular slots at the top and
%   a wide manoeuvring aisle below it.

% ---------------------------------------------------------------- map ----
cfg.map.res      = 0.10;          % [m] occupancy grid resolution
cfg.map.xlim     = [0, 30];       % [m]
cfg.map.ylim     = [0, 18];       % [m]

% ------------------------------------------------------------ vehicle ----
cfg.veh.length        = 4.50;     % [m] bumper to bumper
cfg.veh.width         = 1.85;     % [m]
cfg.veh.wheelbase     = 2.70;     % [m]
cfg.veh.rear_overhang = 0.90;     % [m] rear axle -> rear bumper
cfg.veh.front_overhang= 0.90;     % [m] front axle -> front bumper
cfg.veh.max_steer     = deg2rad(35);
cfg.veh.max_steer_rate= deg2rad(40);
cfg.veh.max_speed     = 1.00;     % [m/s] forward
cfg.veh.max_rev_speed = 0.40;     % [m/s] reverse
cfg.veh.accel         = 1.00;     % [m/s^2]

% --------------------------------------------------------------- slots ---
% Top row: slot opening (entrance) at y = 11.0, slot back wall at y = 16.2.
cfg.slots.top.y_entrance = 11.0;
cfg.slots.top.depth      = 5.2;
cfg.slots.top.width      = 2.8;
cfg.slots.top.x_start    = 4.0;
cfg.slots.top.count      = 8;
cfg.slots.top.divider    = 0.10;

cfg.slots.target         = 4;     % 1-based index in the top row
cfg.slots.final_clearance= 0.30;  % [m] rear bumper to slot back wall

% Parked cars in the non-target slots.  Slightly smaller than the ego car to
% keep the visualisation readable.
cfg.parked.width  = 1.80;
cfg.parked.length = 4.40;
cfg.parked.inset  = 0.15;         % [m] rear bumper to slot entrance

% ------------------------------------------------------------- control ---
cfg.ctrl.dt             = 0.02;   % [s]
cfg.ctrl.shift_time     = 0.90;   % [s] standstill while changing gear
cfg.ctrl.k_theta        = 2.20;   % heading-error gain
cfg.ctrl.k_lat          = 1.20;   % lateral-error gain [1/m]
cfg.ctrl.reverse_radius = 4.80;   % [m] fixed reverse-arc radius
cfg.ctrl.forward_gain   = 0.80;   % speed = gain * remaining distance
cfg.ctrl.reverse_gain   = 0.70;
cfg.ctrl.min_speed      = 0.08;   % [m/s]

% ------------------------------------------------------------ simulation -
cfg.sim.max_time        = 120;    % [s] hard timeout per case
cfg.sim.start_y         = [5.8, 7.0];   % [m] random start band in aisle
cfg.sim.start_x         = [1.5, 28.5];  % [m]
cfg.sim.heading_noise   = deg2rad(20);
cfg.sim.steer_noise     = deg2rad(20);
cfg.sim.seed            = 2026;
cfg.sim.margin          = 0.08;   % [m] extra safety margin for collision
cfg.sim.verbose         = false;

% ----------------------------------------------------------- validation --
cfg.mc.cases            = 1000;
cfg.mc.goal_pos_tol     = 0.15;   % [m]
cfg.mc.goal_head_tol    = deg2rad(3.0);

% ------------------------------------------------------------ reporting --
cfg.vis.enabled         = true;
cfg.vis.animate         = false;
cfg.vis.outdir          = 'results';
end
