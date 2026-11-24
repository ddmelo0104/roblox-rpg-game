--!strict
--[[
	Build.luau
	Small helpers to build the provisional world out of parts (US-052 to US-054): anchored blocks,
	wedges, balls and cylinders with a material and a color, gable roofs, the eight-pointed star of
	Stardawn, text on a face, lights, fire and smoke. Decoration that nobody should bump into or aim
	at goes without collision, queries and shadows (Mundo e Terreno tab, optimization checklist):
	`collide = false` also takes the part out of raycasts, so it never blocks the line of sight.
]]

export type Style = {
	material: Enum.Material?,
	color: Color3?,
	transparency: number?,
	reflectance: number?,
	-- Collides and is hit by raycasts (default true).
	collide: boolean?,
	-- Casts a shadow (default true).
	shadow: boolean?,
	name: string?,
}

export type TextStyle = {
	color: Color3?,
	font: Enum.Font?,
	-- Pixels per stud of the face: more pixels make the text smaller.
	pixelsPerStud: number?,
}

local DEFAULT_COLOR = Color3.fromRGB(200, 200, 200)
local TEXT_COLOR = Color3.fromRGB(240, 205, 120)
local TEXT_FONT = Enum.Font.Antique
local PIXELS_PER_STUD = 40

local Build = {}

local function setUp(part: BasePart, size: Vector3, cframe: CFrame, style: Style?, parent: Instance)
	local s: Style = style or {}
	part.Name = s.name or part.ClassName
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Material = s.material or Enum.Material.SmoothPlastic
	part.Color = s.color or DEFAULT_COLOR
	part.Transparency = s.transparency or 0
	part.Reflectance = s.reflectance or 0
	local collide = s.collide ~= false
	part.CanCollide = collide
	part.CanQuery = collide
	part.CanTouch = false
	part.CastShadow = s.shadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
end

-- A box of `size` centered on `cframe`.
function Build.block(parent: Instance, size: Vector3, cframe: CFrame, style: Style?): Part
	local part = Instance.new("Part")
	setUp(part, size, cframe, style, parent)
	return part
end

-- A wedge: its slope rises from the low edge at the frame's -Z to the high edge at +Z, and its
-- vertical face is at +Z.
function Build.wedge(parent: Instance, size: Vector3, cframe: CFrame, style: Style?): WedgePart
	local part = Instance.new("WedgePart")
	setUp(part, size, cframe, style, parent)
	return part
end

-- A sphere of `diameter` centered on `cframe`.
function Build.ball(parent: Instance, diameter: number, cframe: CFrame, style: Style?): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	setUp(part, Vector3.new(diameter, diameter, diameter), cframe, style, parent)
	return part
end

-- A cylinder centered on `cframe`, its axis along the frame's Y (upright on an upright frame).
function Build.cylinder(parent: Instance, length: number, diameter: number, cframe: CFrame, style: Style?): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	-- A cylinder part's axis is its X: turn it to the frame's Y.
	setUp(part, Vector3.new(length, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), style, parent)
	return part
end

-- A gable roof whose bottom face is centered on `base`: the ridge runs along the frame's X, `height`
-- above it, and the slopes go down to the frame's ±Z.
function Build.gableRoof(
	parent: Instance,
	base: CFrame,
	length: number,
	width: number,
	height: number,
	style: Style?
): { WedgePart }
	local size = Vector3.new(length, height, width / 2)
	local near = Build.wedge(parent, size, base * CFrame.new(0, height / 2, -width / 4), style)
	local far =
		Build.wedge(parent, size, base * CFrame.new(0, height / 2, width / 4) * CFrame.Angles(0, math.pi, 0), style)
	return { near, far }
end

-- The eight-pointed star of Stardawn (Facções tab, the city's crest): two square plates, one turned
-- 45° about the frame's Z, which is where the star faces.
function Build.star(parent: Instance, cframe: CFrame, size: number, thickness: number, style: Style?): { Part }
	local plateSize = Vector3.new(size, size, thickness)
	return {
		Build.block(parent, plateSize, cframe, style),
		Build.block(parent, plateSize, cframe * CFrame.Angles(0, 0, math.rad(45)), style),
	}
end

-- A light inside `part`.
function Build.light(part: BasePart, color: Color3, range: number, brightness: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = part
	return light
end

-- Flames on `part` (no asset needed).
function Build.fire(part: BasePart, size: number, heat: number, color: Color3, secondary: Color3): Fire
	local fire = Instance.new("Fire")
	fire.Size = size
	fire.Heat = heat
	fire.Color = color
	fire.SecondaryColor = secondary
	fire.Parent = part
	return fire
end

-- Smoke rising from `part` (no asset needed).
function Build.smoke(part: BasePart, color: Color3, opacity: number, size: number, rise: number): Smoke
	local smoke = Instance.new("Smoke")
	smoke.Color = color
	smoke.Opacity = opacity
	smoke.Size = size
	smoke.RiseVelocity = rise
	smoke.Parent = part
	return smoke
end

-- `text` written on the `face` of `part`, lit like the part.
function Build.text(part: BasePart, face: Enum.NormalId, text: string, style: TextStyle?): SurfaceGui
	local s: TextStyle = style or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = `Text{face.Name}`
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = s.pixelsPerStud or PIXELS_PER_STUD
	gui.LightInfluence = 1
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = s.font or TEXT_FONT
	label.TextColor3 = s.color or TEXT_COLOR
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.55
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.Parent = label
	return gui
end

-- An empty model or folder inside `parent` (nil: not in the world yet, so its parts replicate at
-- once when it is placed).
function Build.model(parent: Instance?, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Build.folder(parent: Instance?, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

return table.freeze(Build)
