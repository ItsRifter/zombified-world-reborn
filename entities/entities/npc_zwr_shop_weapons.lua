AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "ai"
ENT.Model = "models/player/odessa.mdl"
ENT.PrintName = "Urien (Weapons Dealer)"

local lastUse = 0

function ENT:Initialize()
    self:SetModel(self.Model)
    
    if SERVER then
        self:SetActivity(ACT_IDLE)
        self:SetHullType(HULL_HUMAN)
        self:SetHullSizeNormal()
        self:SetNPCState(NPC_STATE_IDLE)
        self:SetSolid(SOLID_BBOX)
        self:DropToFloor()
    end
end

function ENT:Use(activator, caller)
    if lastUse > CurTime() then return end

    lastUse = 3 + CurTime()

    net.Start("ZWR_OpenShop")
    net.WriteString("weapon")
    net.Send(activator)
end

function ENT:OnTakeDamage( dmgInfo )
    return false
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end

