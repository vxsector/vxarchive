--gve alpha by VXSec

local player = game:GetService("Players").LocalPlayer
local backpack = player:WaitForChild("Backpack")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 370, 0, 200)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "GVE v1 Alpha"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
Title.Parent = MainFrame

MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Selectable = true

                local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)  -- Adjust the corner radius as needed
        corner.Parent = Title

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.BackgroundColor3 = Color3.new(0.8, 0.1, 0.1)
CloseButton.Parent = MainFrame

-- Minimize button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -70, 0, 5)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.1)
MinimizeButton.Parent = MainFrame

-- Function to close the GUI
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Function to minimize the GUI
local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Visible = false

        -- Create a new ScreenGui for the reopen button
        local reopenGui = Instance.new("ScreenGui")
        reopenGui.Parent = game.CoreGui

        -- Create a button to reopen the GUI
        local reopenButton = Instance.new("TextButton")
        reopenButton.Size = UDim2.new(0, 50, 0, 50)
        reopenButton.Position = UDim2.new(0, 1700, 0, 10)
        reopenButton.Text = "Open"
        reopenButton.TextColor3 = Color3.new(1, 1, 1)
        reopenButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        reopenButton.Parent = reopenGui

                local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)  -- Adjust the corner radius as needed
        corner.Parent = reopenButton
        
        -- Function to reopen the GUI
        reopenButton.MouseButton1Click:Connect(function()
            MainFrame.Visible = true  -- Show the main GUI again
            reopenGui:Destroy()  -- Remove the reopen button
            updateBackpackGUI()
        end)
    else
        MainFrame.Visible = true  -- Show the main GUI
    end
end)


-- Scrolling frame for displaying backpack items and attachments
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(0.5, -10, 1, -50)
ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
ScrollFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
ScrollFrame.Parent = MainFrame

-- Right panel for detailed item inspection
local DetailsFrame = Instance.new("ScrollingFrame")
DetailsFrame.Size = UDim2.new(0.5, -10, 1, -50)
DetailsFrame.Position = UDim2.new(0.5, 5, 0, 45)
DetailsFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DetailsFrame.ScrollBarThickness = 6
DetailsFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
DetailsFrame.Parent = MainFrame

-- Single Back button for navigating back to the previous screen
local BackButton = Instance.new("TextButton")
BackButton.Size = UDim2.new(0, 100, 0, 30)
BackButton.Position = UDim2.new(0, 5, 0, 5)
BackButton.Text = "Back"
BackButton.TextColor3 = Color3.new(1, 1, 1)
BackButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
BackButton.Visible = false  -- Initially hidden
BackButton.Parent = MainFrame

-- Function to make the GUI draggable
local dragging
local dragInput
local startPos

local function makeDraggable(frame, titleBar)
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = input.Position
            dragInput = game:GetService("RunService").RenderStepped:Connect(function()
                if dragging then
                    local delta = input.Position - startPos
                    frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + delta.X, frame.Position.Y.Scale, frame.Position.Y.Offset + delta.Y)
                end
            end)
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if dragInput then dragInput:Disconnect() end
        end
    end)
end

-- Make the main frame draggable from the title
makeDraggable(MainFrame, Title)

-- Function to create labels and textboxes for each NumberValue in "Stats"
local function createStatEntry(parent, name, value, index)
    local EntryFrame = Instance.new("Frame")
    EntryFrame.Size = UDim2.new(1, 0, 0, 30)
    EntryFrame.Position = UDim2.new(0, 0, 0, 30 * index)
    EntryFrame.BackgroundTransparency = 1
    EntryFrame.Parent = parent

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, -5, 1, 0)
    NameLabel.Position = UDim2.new(0, 0, 0, 0)
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Parent = EntryFrame

    local ValueBox = Instance.new("TextBox")
    ValueBox.Size = UDim2.new(0.5, -5, 1, 0)
    ValueBox.Position = UDim2.new(0.5, 0, 0, 0)
    ValueBox.Text = tostring(value.Value)
    ValueBox.TextColor3 = Color3.new(1, 1, 1)
    ValueBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    ValueBox.Parent = EntryFrame

    -- Update the actual value when the textbox is edited
    ValueBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(ValueBox.Text)
            if newValue then
                value.Value = newValue  -- Update the NumberValue in the Backpack
            else
                ValueBox.Text = tostring(value.Value)  -- Reset if input is invalid
            end
        end
    end)
end

-- Function to display NumberValues in "Stats" for the selected tool from the AttachmentFolder
local function displayToolStats(tool)
    DetailsFrame:ClearAllChildren()  -- Clear previous details
    BackButton.Visible = true  -- Show the back button

    local index = 0  -- Index for positioning elements
    local statsFolder = tool:FindFirstChild("Stats")
    if statsFolder and statsFolder:IsA("Folder") then
        for _, stat in ipairs(statsFolder:GetChildren()) do
            if stat:IsA("NumberValue") then
                createStatEntry(DetailsFrame, stat.Name, stat, index)
                index = index + 1  -- Move to next line
            end
        end
    else
        -- Display a message if no Stats folder is found
        local noStatsLabel = Instance.new("TextLabel")
        noStatsLabel.Size = UDim2.new(1, 0, 0, 30)
        noStatsLabel.Position = UDim2.new(0, 0, 0, 0)
        noStatsLabel.Text = "No 'Stats' folder found."
        noStatsLabel.TextColor3 = Color3.new(1, 0, 0)
        noStatsLabel.BackgroundTransparency = 1
        DetailsFrame:ClearAllChildren()  -- Clear previous details
        noStatsLabel.Parent = DetailsFrame
    end

    -- Adjust CanvasSize to fit all items in DetailsFrame
    DetailsFrame.CanvasSize = UDim2.new(0, 0, 0, 30 * index)
end

-- Function to display tools in the AttachmentFolder
local function displayAttachmentTools(attachmentFolder)
    ScrollFrame:ClearAllChildren()  -- Clear old entries
    DetailsFrame:ClearAllChildren()  -- Clear previous details
    BackButton.Visible = true  -- Hide back button initially

    local index = 0  -- Start index for stacking entries
    for _, tool in ipairs(attachmentFolder:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = tool.Name
            
            -- Create button for each tool in the AttachmentFolder
            local toolButton = Instance.new("TextButton")
            toolButton.Size = UDim2.new(1, 0, 0, 30)
            toolButton.Position = UDim2.new(0, 0, 0, 30 * index)
            toolButton.Text = "Tool: " .. toolName
            toolButton.TextColor3 = Color3.new(1, 1, 1)
            toolButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
            toolButton.Parent = ScrollFrame
            
            index = index + 1  -- Move to next line

            -- On-click function to display stats in DetailsFrame
            toolButton.MouseButton1Click:Connect(function()
                displayToolStats(tool)  -- Display stats for the selected tool
            end)
        end
    end

    -- Adjust CanvasSize to fit all items in ScrollFrame
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 30 * index)
end

-- Function to update the GUI with current backpack items
local function updateBackpackGUI()
    ScrollFrame:ClearAllChildren()  -- Clear old entries
    DetailsFrame:ClearAllChildren()  -- Clear previous details
    BackButton.Visible = false  -- Hide back button initially
    
    local index = 0  -- Start index for stacking entries
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            -- Create label for each item in the backpack
            local itemName = item.Name
            
            local itemButton = Instance.new("TextButton")
            itemButton.Size = UDim2.new(1, 0, 0, 30)
            itemButton.Position = UDim2.new(0, 0, 0, 30 * index)
            itemButton.Text = "Item: " .. itemName
            itemButton.TextColor3 = Color3.new(1, 1, 1)
            itemButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
            itemButton.Parent = ScrollFrame
            
            index = index + 1  -- Move to next line

            -- On-click function to display attachment folder contents
            itemButton.MouseButton1Click:Connect(function()
                local attachmentFolder = item:FindFirstChild("AttachmentFolder")
                if attachmentFolder and attachmentFolder:IsA("Folder") then
                    displayAttachmentTools(attachmentFolder)  -- Display tools in the AttachmentFolder
                else
                    -- Display a message if no AttachmentFolder is found
                    local noAttachmentLabel = Instance.new("TextLabel")
                    noAttachmentLabel.Size = UDim2.new(1, 0, 0, 30)
                    noAttachmentLabel.Position = UDim2.new(0, 0, 0, 0)
                    noAttachmentLabel.Text = "No 'AttachmentFolder' found."
                    noAttachmentLabel.TextColor3 = Color3.new(1, 0, 0)
                    noAttachmentLabel.BackgroundTransparency = 1
                    DetailsFrame:ClearAllChildren()  -- Clear previous details
                    noAttachmentLabel.Parent = DetailsFrame
                end
            end)
        end
    end
    
    -- Adjust CanvasSize to fit all items in ScrollFrame
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 30 * index)
end

-- Back button functionality to navigate back to the previous screen
BackButton.MouseButton1Click:Connect(function()
    DetailsFrame:ClearAllChildren()  -- Clear current stats
    BackButton.Visible = false  -- Hide back button
    updateBackpackGUI()  -- Show the tools in the backpack again
end)

-- Initial update of the GUI
updateBackpackGUI()

-- Update GUI whenever the Backpack contents change
backpack.ChildAdded:Connect(updateBackpackGUI)
backpack.ChildRemoved:Connect(updateBackpackGUI)
