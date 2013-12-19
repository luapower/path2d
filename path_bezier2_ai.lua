--2d quadratic bezier adaptive interpolation from AGG.
--adapted from http://www.antigrain.com/research/adaptive_bezier/index.html by Cosmin Apreutesei.

local bezier2 = require'path_bezier2'

local pi, atan2, abs, radians = math.pi, math.atan2, math.abs, math.rad

local curve_collinearity_epsilon    = 1e-30
local curve_angle_tolerance_epsilon = 0.01
local curve_recursion_limit         = 32

local recursive_bezier --forward decl.

--tip: adjust m_approximation_scale to the scale of the world-to-screen transformation.
--tip: enable m_angle_tolerance when stroke width * scale > 1.
function bezier2.interpolate(write, x1, y1, x2, y2, x3, y3, m_approximation_scale, m_angle_tolerance)
	m_approximation_scale = m_approximation_scale or 1
	m_angle_tolerance = m_angle_tolerance and radians(m_angle_tolerance) or 0
	local m_distance_tolerance2 = (1 / (2 * m_approximation_scale))^2

	recursive_bezier(write, x1, y1, x2, y2, x3, y3, 0, m_distance_tolerance2, m_angle_tolerance)
	write('line', x3, y3)
end

function recursive_bezier(write, x1, y1, x2, y2, x3, y3, level, m_distance_tolerance2, m_angle_tolerance)
	if level > curve_recursion_limit then return end

	-- Calculate all the mid-points of the line segments
	local x12   = (x1 + x2) / 2
	local y12   = (y1 + y2) / 2
	local x23   = (x2 + x3) / 2
	local y23   = (y2 + y3) / 2
	local x123  = (x12 + x23) / 2
	local y123  = (y12 + y23) / 2

	local dx = x3-x1
	local dy = y3-y1
	local d = abs((x2 - x3) * dy - (y2 - y3) * dx)

	if d > curve_collinearity_epsilon then
		-- Regular case
		if d^2 <= m_distance_tolerance2 * (dx^2 + dy^2) then
			-- If the curvature doesn't exceed the distance_tolerance value we tend to finish subdivisions.
			if m_angle_tolerance < curve_angle_tolerance_epsilon then
				write('line', x123, y123)
				return
			end
			-- Angle & Cusp Condition
			local da = abs(atan2(y3 - y2, x3 - x2) - atan2(y2 - y1, x2 - x1))
			if da >= pi then
				da = 2*pi - da
			end
			if da < m_angle_tolerance then
				write('line', x123, y123)
				return
			end
		end
	else
		-- Collinear case
		dx = x123 - (x1 + x3) / 2
		dy = y123 - (y1 + y3) / 2
		if dx^2 + dy^2 <= m_distance_tolerance2 then
			write('line', x123, y123)
			return
		end
	end

	-- Continue subdivision
	recursive_bezier(write, x1, y1, x12, y12, x123, y123, level + 1, m_distance_tolerance2, m_angle_tolerance)
	recursive_bezier(write, x123, y123, x23, y23, x3, y3, level + 1, m_distance_tolerance2, m_angle_tolerance)
end

if not ... then require'path_bezier2_demo' end

