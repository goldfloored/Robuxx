--!nonstrict
-- BeachEnvironment — procedural low-poly tropical beach assets (palms, sand, grass).
--
-- MEMORY OPTIMISATION (the pattern we worked out):
--   Every asset's geometry is built from primitive Parts ONCE, then baked into a
--   single Union instance. That one template is CLONED for every placed copy — so
--   a forest of 40 palms is ~40 instances in memory instead of 40 x ~100 parts.
--   Scaling/rotation is applied per-clone; the source geometry is never rebuilt.
--
-- Quick test (paste into the Studio command bar, or a Script):
--   local Beach = require(game.ReplicatedStorage.Shared.BeachEnvironment)
--   Beach.generateTestScene()        -- builds a demo beach under workspace.BeachEnv
--   workspace.BeachEnv:Destroy()     -- ...and removes it again
--
-- Individual pieces:
--   Beach.plantPalms({ parent = workspace, count = 40, minRadius = 70, maxRadius = 235 })
--   Beach.createSand({ parent = workspace, size = 400 })
--   Beach.createGrassPatch({ parent = workspace, size = Vector2.new(120, 80), position = Vector3.new(0, 0, -90) })

local BeachEnvironment = {}

-- ───────────────────────────── Config ─────────────────────────────
-- Tweak these to restyle everything. Every value can also be overridden per call.
local CONFIG = {
	Trunk = {
		segments = 7,          -- number of stacked cylinder segments
		height = 14,           -- total trunk height (studs) before scaling
		baseRadius = 0.95,     -- thickness at the base
		topRadius = 0.45,      -- thickness at the crown (tapers)
		lean = 0.22,           -- 0 = straight, higher = more organic curve
		color = Color3.fromRGB(178, 132, 86), -- light brown / tan
	},
	Fronds = {
		count = 9,             -- leaves in the starburst
		length = 6.5,
		width = 1.8,
		thickness = 0.4,       -- flat blades
		droop = 0.55,          -- how much the fronds sag downward
		lightColor = Color3.fromRGB(120, 205, 85),
		darkColor = Color3.fromRGB(74, 162, 64),
	},
	Sand = { color = Color3.fromRGB(238, 223, 173), thickness = 4 },   -- cream beach sand
	Grass = { color = Color3.fromRGB(104, 196, 78), thickness = 1, lift = 0.25 }, -- vibrant turf
}

-- ───────────────────────────── Helpers ────────────────────────────
local function merge(base, override)
	local t = {}
	for k, v in pairs(base) do t[k] = v end
	if override then for k, v in pairs(override) do t[k] = v end end
	return t
end

-- One flat-shaded, anchored, collidable part — the low-poly cartoon look.
local function newPart(shape, size, cframe, color, parent)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic   -- no realistic noise
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = false   -- shadows off for now (they were noisy/buggy on the palms)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- An orthonormal CFrame whose local X axis (a cylinder's axis / a frond's length)
-- points along `dir`. Used to aim trunk segments and leaves in any direction.
local function axisCFrame(center, dir)
	dir = dir.Unit
	local ref = math.abs(dir.Y) < 0.99 and Vector3.yAxis or Vector3.xAxis
	local up = ref:Cross(dir)
	if up.Magnitude < 1e-4 then up = Vector3.xAxis:Cross(dir) end
	return CFrame.fromMatrix(center, dir, up.Unit)
end

-- Lowest world-Y of an oriented box — lets us drop any asset flush onto the ground.
local function worldMinY(cf, size)
	local mn = math.huge
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local c = cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
				mn = math.min(mn, c.Y)
			end
		end
	end
	return mn
end

-- Position a Model at (x, z), spun about the vertical, with its base flush to groundY.
local function placeFlush(model, x, z, spin, groundY)
	model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, spin, 0) * model:GetPivot().Rotation)
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(0, groundY - worldMinY(cf, size), 0))
end

-- Make a placed palm touchable & climbable WITHOUT a canopy-wide wall: a slim
-- TrussPart up the trunk (solid so you bump it / climb it with W) and a small cap
-- at the crown to stand on. The visual union stays non-colliding, so the only
-- colliders are at the trunk + a tiny crown cap — never an empty-space wall.
-- Sized to the placed model, so call AFTER placeFlush.
local function addClimbStructure(model)
	local cf, size = model:GetBoundingBox()
	local bottom = cf.Y - size.Y / 2
	local th = size.Y * 0.9
	local truss = Instance.new("TrussPart")
	truss.Name = "ClimbTruss"
	truss.Size = Vector3.new(2, th, 2)
	truss.Anchored = true; truss.CanCollide = true; truss.Transparency = 1; truss.CastShadow = false
	truss.CFrame = CFrame.new(cf.X, bottom + th / 2, cf.Z)
	truss.Parent = model
	local cap = Instance.new("Part")
	cap.Name = "TopCap"
	cap.Size = Vector3.new(3, 1, 3)
	cap.Anchored = true; cap.CanCollide = true; cap.Transparency = 1; cap.CastShadow = false
	cap.CFrame = CFrame.new(cf.X, bottom + th, cf.Z)
	cap.Parent = model
end

-- ──────────────────────────── Palm tree ───────────────────────────
local function buildTrunk(model, t)
	local pos = Vector3.zero
	local segLen = t.height / t.segments
	local leanDir = Vector3.new(1, 0, 0.35).Unit       -- direction the trunk curves toward
	local top, dir = pos, Vector3.yAxis
	for i = 1, t.segments do
		local f = (i - 1) / math.max(t.segments - 1, 1) -- 0 at base → 1 at crown
		dir = (Vector3.yAxis + leanDir * (t.lean * f)).Unit
		local r = t.baseRadius + (t.topRadius - t.baseRadius) * f
		local center = pos + dir * (segLen / 2)
		-- Cylinder shape: Size.X is the round axis, so it runs along `dir`.
		newPart(Enum.PartType.Cylinder, Vector3.new(segLen + 0.15, r * 2, r * 2),
			axisCFrame(center, dir), t.color, model)
		pos = pos + dir * segLen
		top = pos
	end
	return top
end

local function buildFronds(model, top, f)
	-- a small rounded crown nub so the fronds emerge from a clean centre
	newPart(Enum.PartType.Ball, Vector3.new(f.width, f.width, f.width) * 0.9,
		CFrame.new(top), f.darkColor, model)
	for j = 1, f.count do
		local a = (j - 1) / f.count * math.pi * 2
		local outward = Vector3.new(math.cos(a), 0, math.sin(a))
		local dir = (outward + Vector3.new(0, -f.droop, 0)).Unit       -- out and drooping
		local center = top + dir * (f.length / 2) + Vector3.new(0, 0.3, 0)
		local color = (j % 2 == 0) and f.lightColor or f.darkColor
		-- Flat blade: X = length (along dir), Y = thin, Z = width.
		newPart(Enum.PartType.Block, Vector3.new(f.length, f.thickness, f.width),
			axisCFrame(center, dir), color, model)
	end
end

-- Build a palm as a part Model (un-baked). Base sits at the model origin's y = 0.
function BeachEnvironment.createPalm(opts)
	opts = opts or {}
	local t = merge(CONFIG.Trunk, opts.trunk)
	local f = merge(CONFIG.Fronds, opts.fronds)
	local model = Instance.new("Model")
	model.Name = "Palm"
	local top = buildTrunk(model, t)
	buildFronds(model, top, f)
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	return model
end

-- Build a palm ONCE and bake it into a single Union, wrapped in a Model template.
-- This is the asset we clone for every tree. Falls back to the part Model if
-- UnionAsync is unavailable (returns a valid template either way).
function BeachEnvironment.bakePalm(opts)
	local model = BeachEnvironment.createPalm(opts)
	model.Parent = workspace                       -- UnionAsync needs parts in the DataModel

	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts + 1] = d end
	end

	if #parts >= 2 then
		local rest = {}
		for i = 2, #parts do rest[i - 1] = parts[i] end
		local ok, union = pcall(function()
			return parts[1]:UnionAsync(rest, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Performance)
		end)
		if ok and union then
			union.Name = "PalmMesh"
			union.UsePartColor = false             -- keep each part's original colour
			union.Anchored = true
			union.CastShadow = false               -- shadows off for now
			-- The visual mesh is always non-colliding: a Union's collider is its
			-- bounding BOX (canopy-wide) = invisible walls. Touch/climb collision is
			-- provided by the slim trunk truss + crown cap added in plantPalms, so the
			-- only solid bits sit on the visible trunk, never in empty space.
			union.CanCollide = false
			local wrapper = Instance.new("Model")
			wrapper.Name = "Palm"
			union.Parent = wrapper
			wrapper.PrimaryPart = union
			model:Destroy()
			wrapper.Parent = nil                   -- detached template, ready to clone
			return wrapper
		end
		warn("[BeachEnvironment] UnionAsync failed; using part-model template (less optimal).")
	end

	model.Parent = nil
	return model
end

-- Plant a forest: bake ONE template, then clone it `count` times at random sizes
-- around a ring, leaving the centre (< minRadius) open and walkable.
function BeachEnvironment.plantPalms(opts)
	opts = opts or {}
	local parent = opts.parent or workspace
	local count = opts.count or 40
	local minR, maxR = opts.minRadius or 70, opts.maxRadius or 235
	local minH, maxH = opts.minHeight or 20, opts.maxHeight or 46
	local centre = opts.center or Vector3.zero
	local groundY = opts.groundY or 0
	local walkable = opts.walkable == true   -- default false: solid trunk + climb-truss + top cap

	local template = opts.template or BeachEnvironment.bakePalm(opts)
	local _, baseSize = template:GetBoundingBox()
	local baseHeight = baseSize.Y

	local folder = Instance.new("Folder")
	folder.Name = opts.folderName or "Palms"
	folder.Parent = parent

	math.randomseed(opts.seed or (os.clock() * 1e6) % 2 ^ 31)
	for _ = 1, count do
		local ang = math.random() * math.pi * 2
		local r = minR + math.random() * (maxR - minR)
		local x = centre.X + math.cos(ang) * r
		local z = centre.Z + math.sin(ang) * r
		local scale = (minH + math.random() * (maxH - minH)) / baseHeight
		local clone = template:Clone()
		clone:ScaleTo(scale)
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then d.CanCollide = false; d.CastShadow = false end
		end
		placeFlush(clone, x, z, math.random() * math.pi * 2, groundY)
		clone.Parent = folder
		if not walkable then addClimbStructure(clone) end   -- touchable + climbable
	end

	if opts.keepTemplate then template.Parent = opts.parent or workspace end
	return folder
end

-- ─────────────────────────── Ground pieces ────────────────────────
-- Big, blocky, smooth beach-sand plate. Top surface sits at `position.Y` (default 0).
function BeachEnvironment.createSand(opts)
	opts = opts or {}
	local s = merge(CONFIG.Sand, opts)
	local size = opts.size or 300
	local pos = opts.position or Vector3.zero
	return newPart(Enum.PartType.Block,
		Vector3.new(size, s.thickness, size),
		CFrame.new(pos + Vector3.new(0, -s.thickness / 2, 0)),
		s.color, opts.parent or workspace)
end

-- Flat vibrant-green turf panel, slightly raised above the sand for a clean border.
function BeachEnvironment.createGrassPatch(opts)
	opts = opts or {}
	local g = merge(CONFIG.Grass, opts)
	local size = opts.size or Vector2.new(120, 80)
	local pos = opts.position or Vector3.zero
	local part = newPart(Enum.PartType.Block,
		Vector3.new(size.X, g.thickness, size.Y),
		CFrame.new(pos + Vector3.new(0, g.lift, 0)),
		g.color, opts.parent or workspace)
	part.Name = "GrassPatch"
	return part
end

-- ──────────────────────────── Test harness ────────────────────────
-- One call that lays down a demo beach so you can eyeball the style fast.
function BeachEnvironment.generateTestScene(opts)
	opts = opts or {}
	local root = Instance.new("Folder")
	root.Name = "BeachEnv"
	root.Parent = opts.parent or workspace

	BeachEnvironment.createSand({ parent = root, size = opts.size or 360 })
	-- a couple of turf borders near the back
	BeachEnvironment.createGrassPatch({ parent = root, size = Vector2.new(150, 70), position = Vector3.new(0, 0, -110) })
	BeachEnvironment.createGrassPatch({ parent = root, size = Vector2.new(70, 70), position = Vector3.new(110, 0, -40) })
	-- the optimised palm forest (edges only; centre stays open)
	BeachEnvironment.plantPalms({
		parent = root, count = opts.count or 40,
		minRadius = 60, maxRadius = 165, minHeight = 18, maxHeight = 42,
	})

	return root
end

return BeachEnvironment
