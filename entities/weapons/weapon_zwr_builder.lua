AddCSLuaFile()

if SERVER then
    util.AddNetworkString("ZWR_Builder_Update")
end

SWEP.Author         = "Rifter"
SWEP.Base           = "weapon_base"
SWEP.PrintName      = "Faction Construction Builder"
SWEP.Instructions   = "Mouse 1: Build the desired construction\nMouse 2: Select construction"

SWEP.ViewModel      = "models/weapons/c_slam.mdl"
SWEP.WorldModel     = "models/weapons/w_slam.mdl"

SWEP.Weight         = 0
SWEP.Slot           = 4

SWEP.DrawAmmo       = false 
SWEP.DrawCrosshair  = true

SWEP.SetHoldType    = "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = -1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = -1

SWEP.BuildRange = 150
SWEP.Delay = 2
SWEP.NextBuild = 0
SWEP.NextOpenMenu = 0

SWEP.RotateAngle = 0
SWEP.RotateSpeed = 75
function SWEP:Deploy()
    self.Owner.Buildings = self.Owner.Buildings or {}
end

function SWEP:Reload()
    if not self.Owner.HoloBuild or not self.Owner.HoloBuild:IsValid() then return end
    
    if self.RotateAngle > 360 then
        self.RotateAngle = 0 
    elseif self.RotateAngle < 0 then
        self.RotateAngle = 360
    end

    self.RotateAngle = self.RotateSpeed * CurTime()

    self.Owner.HoloBuild:SetAngles(Angle(0, self.RotateAngle, 0))
end

function SWEP:PrimaryAttack()
    if self.NextBuild > CurTime() then return end
    if self.Owner.HoloBuild == nil or not self.Owner.HoloBuild:IsValid() then return end
    
    local tempCheck

    for _, t in pairs(GAMEMODE.DB.Buildings) do
        if t.Model == self.Owner.HoloBuild:GetModel() then
            tempCheck = t
        end
    end

    for i, b in pairs(self.Owner.Buildings) do
        if not self.Owner.Buildings[i] then continue end
        if self.Owner.Buildings[i] == tempCheck.Class then
            if not self.Owner.TotalBuilding then
                self.Owner.TotalBuilding = 1
            end

            self.Owner.TotalBuilding = self.Owner.TotalBuilding + 1

            if self.Owner.TotalBuilding >= tempCheck.MaxLimit then 
                self.Owner:ChatPrint("You have exceeded the max limit for this building")
                self.Owner.TotalBuilding = nil
                self.NextBuild = self.Delay + CurTime()
                return 
            end
        end
    end

    local building = ents.Create(self.Owner.HoloBuild.Class)
    building:SetPos(self.Owner.HoloBuild:GetPos())
    building:SetAngles(self.Owner.HoloBuild:GetAngles())
    building:Spawn()
    building:SetNWEntity("ZWR_Base_Leader", self.Owner)
    table.insert(self.Owner.Buildings, self.Owner.HoloBuild.Class)

    self.Owner.HoloBuild:Remove()
    self.Owner:EmitSound("buttons/lever" .. math.random(3, 6) .. ".wav")

    self.NextBuild = self.Delay + CurTime()
end

local curFrame = nil

function SWEP:SecondaryAttack()
    if SERVER then return end
    if self.NextOpenMenu > CurTime() then return end
    if curFrame and curFrame:IsValid() then return end 

    self.NextOpenMenu = self.Delay + CurTime()

    local buildingsFrame = vgui.Create("DFrame")
    buildingsFrame:SetTitle("")
    buildingsFrame:SetSize(ScrW() / 1.5, ScrH() / 1.25)
    buildingsFrame:SetDraggable(false)
    buildingsFrame:Center()
    buildingsFrame:MakePopup()

    local buildScroll = vgui.Create( "DScrollPanel", buildingsFrame )
    buildScroll:Dock( FILL )

    local buildList = vgui.Create("DIconLayout", buildScroll)
    buildList:Dock( FILL )
    buildList:SetSpaceY( 5 )
    buildList:SetSpaceX( 5 )

    for _, building in pairs(GAMEMODE.DB.Buildings) do
        local bPanel = buildList:Add("DPanel")
        bPanel:SetSize(350, 250)
        bPanel.Paint = function(self, w, h)
            surface.SetDrawColor(Color(0, 0, 0, 255))
            surface.DrawRect(0, 0, w, h)
        end
        
        local bModel = vgui.Create("DModelPanel", bPanel)
        bModel:SetModel(building.Model)
        bModel:SetSize(bPanel:GetWide() / 2, bPanel:GetTall())
        bModel:SetPos(bPanel:GetWide() / 2, bPanel:GetTall() / 12)
        function bModel:LayoutEntity( ent ) return end

        local bDesc = vgui.Create("DLabel", bPanel)
        bDesc:SetText(building.Name .. "\n" .. building.Desc .. "\nCost: " .. building.Cost)
        bDesc:SetFont("ZWR_QMenu_Faction_BuildDesc")
        bDesc:SizeToContents()

        local selectBtn = vgui.Create("DButton", bPanel)
        selectBtn:SetText("Select Building")
        selectBtn:SetSize(128, 32)
        selectBtn:SetPos(0, bPanel:GetTall() - selectBtn:GetTall())
        selectBtn.DoClick = function()
            if curFrame and curFrame:IsValid() then
                curFrame:Remove()
                net.Start("ZWR_Builder_Update")
                    net.WriteString(building.Class)
                net.SendToServer()
            end
        end
    end

    curFrame = buildingsFrame
end

net.Receive("ZWR_Builder_Update", function(len, ply)
    if not ply then return end

    local holoClass = net.ReadString()
    local newBuild = ents.Create(holoClass)

    ply:SetNWEntity("ZWR_Temp_Building", newBuild)
end)

function SWEP:Think()

    if self.Owner:GetNWEntity("ZWR_Temp_Building"):IsValid() then
        if not self.Owner.HoloBuild or not self.Owner.HoloBuild:IsValid() then
            self.Owner.HoloBuild = ents.Create("ent_zwr_faction_ghostbuild")
        end

        self.Owner.HoloBuild.Class = self.Owner:GetNWEntity("ZWR_Temp_Building"):GetClass()

        for _, m in pairs(GAMEMODE.DB.Buildings) do
            if m.Class == self.Owner.HoloBuild.Class then
                if m.AdjustZPos then
                    self.Owner.HoloBuild.AdjustZPos = m.AdjustZPos
                end
                self.Owner.HoloBuild:SetModel(m.Model)
                self.Owner.HoloBuild:SetMaterial("models/wireframe")
            end

            
        end
        
        self.Owner:SetNWEntity("ZWR_Temp_Building", nil)
    end

    if self.Owner.HoloBuild == nil or not self.Owner.HoloBuild:IsValid() then return end
    self:DrawPreviewModel()
end

function SWEP:Holster()
    if CLIENT then return end

    if self.Owner.HoloBuild and self.Owner.HoloBuild:IsValid() then
        self.Owner.HoloBuild:Remove()
        self.Owner.HoloBuild = nil
    end

    return true
end

function SWEP:DrawPreviewModel() 
    local tr = util.TraceLine({
        start = self.Owner:EyePos(),
        endpos = self.Owner:EyePos() + self.Owner:EyeAngles():Forward() * self.BuildRange,
        filter = function( ent ) 
            if ent:GetClass() == self.Owner.HoloBuild then 
                return false 
            end

            if ent == self.Owner then
                return false 
            end
        end
    } )

    local cosine = tr.HitNormal:Dot(Vector(0, 0, 1))
    
    if tr.Hit and tr.HitWorld and tr.HitNormal.z == 1 then
        tr.HitPos.z = tr.HitPos.z + tr.HitNormal.z + (self.Owner.HoloBuild.AdjustZPos or 1)
    end

    if self.Owner.HoloBuild and self.Owner.HoloBuild:IsValid() then
        if not tr.Hit then
            self.Owner.HoloBuild:SetColor(Color(255, 0, 0))
        elseif cosine < 0.2588190451 then
            self.Owner.HoloBuild:SetColor(Color(255, 0, 0))
        elseif cosine < 0.7071067812 then
            self.Owner.HoloBuild:SetColor(Color(255, 0, 0))
        elseif self:InWallOrNearProp() then
            self.Owner.HoloBuild:SetColor(Color(255, 0, 0))
        elseif tr.HitNormal.z ~= 1 then
            self.Owner.HoloBuild:SetColor(Color(255, 0, 0))
        else
            self.Owner.HoloBuild:SetColor(Color(0, 255, 0))
        end
    end

    self.Owner.HoloBuild:SetPos(tr.HitPos)
end

--Checks if the desired building is in a wall or near a prop
function SWEP:InWallOrNearProp()
   
    local buildCenter = self.Owner.HoloBuild:WorldSpaceCenter()

    for _, ent in pairs(ents.FindInSphere(buildCenter, self.Owner.HoloBuild:BoundingRadius())) do
        if ent and ent ~= self.Owner.HoloBuild and ent:IsValid() then
			local nearest = ent:NearestPoint(buildCenter)
			if self.Owner.HoloBuild:NearestPoint(nearest):DistToSqr(nearest) <= 144 then
				return true
			end
		end
	end

    return false
end

