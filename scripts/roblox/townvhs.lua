local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
local staticImagesFolder = playerGui
    and playerGui:FindFirstChild("NightVisionVHS")
    and playerGui.NightVisionVHS:FindFirstChild("StaticImages")
local vignette = playerGui
    and playerGui:FindFirstChild("NightVisionVHS")
    and playerGui.NightVisionVHS:FindFirstChild("Vignette")

if not staticImagesFolder then
    warn("StaticImages folder not found in the specified path.")
    return
end

local newImageId = "0"

for _, child in ipairs(staticImagesFolder:GetChildren()) do
    if child.Name == "img" and (child:IsA("ImageLabel") or child:IsA("ImageButton")) then
        child.Image = newImageId -- Set ImageId to the new value
    end
end

if vignette and vignette:IsA("GuiObject") then
    vignette.Visible = false
end
