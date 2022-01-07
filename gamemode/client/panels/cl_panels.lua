ZWR = {}

ZWR.Theme = {
	primary = Color(75, 75, 75),
	secondary = Color(35, 35, 35),
	background = Color(100, 100, 100, 150),
	
	scoreboard = {
		primary = Color(50, 50, 50, 245),
		secondary = Color(75, 75, 75, 175),
		playerPanel = Color(0, 0, 0, 255),
	},

	shop = {
		primary = Color(50, 50, 50, 215),
		secondary = Color(75, 75, 75, 175),
		playerPanel = Color(0, 0, 0, 255),
	},

    invSlot = Color(25, 25, 25, 255),

    text = {
		h1 = Color(225, 225, 225),
	},
}

ZWR.UISizes = {
	header = {height = 0},
	navbar = {height = 56},
}

local PANEL = {}

function PANEL:Init()
	self.header = self:Add("Panel")
	self.header:Dock(TOP)
	
	self.header.paint = function(self, w, h)
		draw.RoundedBoxEx(6, 0, 0, w, h, ZWR.Theme.primary, true, true, false, false)
	end
	
	self.header:SetMouseInputEnabled(true)
	self.header:MakePopup()
end

function PANEL:PerformLayout(w, h)
	self.header:SetTall(ZWR.UISizes.header.height)
end

vgui.Register("ZWR_Frame", PANEL, "EditablePanel")

local NAVBAR = {}

AccessorFunc(NAVBAR, "m_body", "Body")

function NAVBAR:Init()
	self.buttons = {}
	self.panels = {}
end

function NAVBAR:AddTab(name, panel)
	local i = table.Count(self.buttons) + 1
	self.buttons[i] = self:Add("DButton")
	local btn = self.buttons[i]
	
	btn.id = i
	
	btn:Dock(LEFT)
	btn:DockMargin(0, 2, 0, 0)
	btn:DockPadding(40, 30, 20, 10)
	btn:SetText(name)
	btn:SetFont("ZWR_QMenu_ButtonText")
	btn:SetTextColor(Color(255, 255, 255, 255))
	
	btn.Paint = function(pnl, w, h)
		if self.active == pnl.id then
			surface.SetDrawColor(ZWR.Theme.text.h1)
			surface.DrawRect(0, h - 2, w, 2)
		end
	end
	
	btn:SizeToContentsX(32)
	
	btn.DoClick = function(pnl)
		if self.active == pnl.id then return end
		self:SetActive(pnl.id)
		surface.PlaySound("buttons/combine_button7.wav")
	end

	self.panels[i] = self:GetBody():Add(panel or "DPanel")
	panel = self.panels[i]
	panel:Dock(FILL)
	panel:SetVisible(false)
	panel.Paint = nil
end

function NAVBAR:GetActive()
	return self.panels[self.active]
end

function NAVBAR:GetActiveID()
	return self.active
end

function NAVBAR:SetActive(id)
	local btn = self.buttons[id]
	if !IsValid(btn) then return end
	
	local activePnl = self.panels[self.active]
	if IsValid(activePnl) then
		activePnl:SetVisible(false)
	end
	
	local panel = self.panels[id]
	panel:SetVisible(true)
	
	self.active = id
	
end

function NAVBAR:Paint(w, h)
	surface.SetDrawColor(ZWR.Theme.secondary)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("ZWR_Navigation", NAVBAR)

local PANEL = {}

function PANEL:Init()
	self.navbar = self:Add("ZWR_Navigation")
	self.navbar:Dock(TOP)
	self.navbar:SetBody(self)
end

function PANEL:PerformLayout(w, h)
	self.BaseClass.PerformLayout(self, w, h)
	
	self.navbar:SetTall(ZWR.UISizes.navbar.height)
end

vgui.Register("ZWR_Tab", PANEL, "ZWR_Frame")

local INV = {}

AccessorFunc(INV, "m_ItemPanel", "ItemPanel")
AccessorFunc(INV, "m_Color", "Color")

function INV:Init()
    self.m_Coords = {x = 0, y = 0}
    self:SetSize(60, 60)
    self:SetColor(Color(200, 200, 200))
    self:SetItemPanel(false)

    self:Receiver("invitem", function(pnl, item, drop, i, x, y) --Drag-drop functionality
	if drop then
		item = item[1]
		local x1, y1 = pnl:GetPos()
		local x2, y2 = item:GetPos()
		if math.Dist(x1, y1, x2, y2) <= 30 then --Find the top left slot.
			if not pnl:GetItemPanel() then
				local itm = item:GetItem()
				local x, y = pnl:GetCoords()
				local itmw, itmh = itm:GetSize() --GetSize needs to be a function in your items system.
				local full = false
				for i1 = x, (x + itmw)-1 do
					if full then break end
					for i2 = y, (y + itmh)-1 do
						if LocalPlayer():GetInvItem(i1,i2):GetItemPanel() then --check if the panels in the area are full.
							full = true
							break
						end
					end
				end
				if not full then --If none of them are full then
					for i1=x, (x+itmw)-1 do
						for i2=y, (y+itmh)-1 do
							LocalPlayer():GetInvItem(i1,i2):SetItemPanel(item) -- Tell all the things below it that they are now full of this item.
						end
					end
					item:SetRoot(pnl) --like a parent, but not a parent.
					item:SetPos(pnl:GetPos()) --move the item.
				end
			end
		end
	else
		--Something about coloring of hovered slots.
	end
end, {})
end

function INV:SetCoords(x, y)
     self.m_Coords.x = x
     self.m_Coords.y = y
end

function INV:GetCoords()
     return self.m_Coords.x, self.m_Coords.y
end

local col
function INV:Paint(w,h)
     draw.NoTexture()
     col = self:GetColor()
     surface.SetDrawColor(col.r, col.g, col.b, 255)
     surface.DrawRect(0, 0, w-2, h-2) --main square
     surface.SetDrawColor(70, 70, 70, 255)
     surface.DrawRect(w-2, 0, h, 2) --borders
     surface.DrawRect(0, h-2, 2, w) -- ^
end

vgui.Register("ZWR_InvSlot", INV, "DPanel")

local InvItem = {}

AccessorFunc(PANEL, "m_Item", "Item")
AccessorFunc(PANEL, "m_Root", "Root")

function InvItem:Init()
     self:SetSize(60, 60)
     self:SetItem(false) --false means no item.
     self:SetColor(Color(100, 100, 100))
     self:SetDroppable("invitem")
end

function InvItem:PaintOver(w,h)
     draw.NoTexture()
     if self:GetItem() then
          surface.SetMaterial(self:GetItem():GetIcon()) --Your items must have a GetIcon method.
          surface.DrawTexturedRect(0, 0, w, h)
     end
end

local col
function InvItem:Paint(w,h)
     draw.NoTexture()
     col = self:GetColor()
     surface.SetDrawColor(col.r, col.g, col.b, 180)
     surface.DrawRect(0, 0, w, h) --background square
end
vgui.Register("ZWR_InvItem", InvItem, "DPanel")