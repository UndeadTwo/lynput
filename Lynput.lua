-- TODO: Implementation without libraries
Object = require("lib.classic.classic")

Lynput = Object:extend()

Lynput.s_lynputs = {}
Lynput.s_idCount = 0
Lynput.s_count = 0

-- TODO: More reserved words such as:
-- - reserved characters
-- - lynput variables stored in "self"
Lynput.s_reserved_words = {
  "and", "break", "do", "else", "elseif", "end", "false", "for", 
  "function", "if", "in", "local", "nil", "not", "or", "repeat", 
  "return", "then", "true", "until", "while"
}

----------------
-- DICTIONARIES
----------------
Lynput.s_mouseButtons = {
  ["1"]="LMB", ["2"]="RMB", ["3"]="MMB", ["x1"]="MB4", ["x2"]="MB5"
}

Lynput.s_gamepadButtons = {
  ["a"]="G_A", ["b"]="G_B", ["x"]="G_X", ["y"]="G_Y",
  ["back"]="G_BACK", ["guide"]="G_GUIDE", ["start"]="G_START",
  ["leftstick"]="G_LEFT_STICK", ["rightstick"]="G_RIGHT_STICK",
  ["leftshoulder"]="G_LB", ["rightshoulder"]="G_RB",
  ["dppup"]="G_DPAD_UP", ["dpdown"]="G_DPAD_DOWN", 
  ["dpleft"]="G_DPAD_LEFT", ["dpright"]="G_DPAD_RIGHT"
}

-----------------------
-- FUTURE DICTIONARIES
-----------------------
-- Lynput.s_mouse_axes = {
--   "wd", "wu"
-- }

-- Lynput.s_gamepad_axes = {
--   "leftx", "lefty", "rightx", "righty", "triggerleft", "triggerright"
-- }

-- -- FIXME: Input names have to be unique, conflict with keyboard
-- -- May add a preffix like gstart for start or ga for a, or gamepad_a for a


function Lynput:new()
  self.inputsSet = {}

  -- TODO: Test gamepad support with more than 1 gamepad
  self.gpad = nil
  
  self.id = tostring(Lynput.s_idCount)
  Lynput.s_lynputs[self.id] = self
  Lynput.s_idCount = Lynput.s_idCount + 1
  Lynput.s_count = Lynput.s_count + 1
end


local function _isActionValid(action)
  if type(action) ~= "string" then
    return false
  end -- if not string
  
  for i,v in ipairs(Lynput.s_reserved_words) do
    if v == action then
      return false
    end -- if s_reserved_word
  end -- for each s_reserved_words
  
  return true
end


local function _isCommandValid(command)
  local state, input = string.match(command, "(%w+)%s(.+)")
  
  -- Process state
  local stateValid =
    state == "release" or
    state == "press" or
    state == "hold"
  
  -- Process input
  local inputValid = false
  for _,v in pairs(Lynput.s_mouseButtons) do
    if v == input then
      inputValid = true
    end -- if v == input
  end -- for each Lynput mouse button
  
  for _,v in pairs(Lynput.s_gamepadButtons) do
    if v == input then
      inputValid = true
    end -- if v == input
  end -- for each Lynput gamepad button
  
  -- TODO: Gamepad axes
  -- TODO: Touch screen
  
  if not inputValid then
    inputValid = pcall(love.keyboard.getScancodeFromKey, input)
  end -- if not inputValid

  return stateValid and inputValid, state, input
end


function Lynput:remove()
  Lynput.s_lynputs[self.id] = nil
  Lynput.s_count = Lynput.s_count - 1
end


-- @gamepad is a Lynput gamepad string name (e.g., "GPAD_1" for Lynput.GPAD_1)
function Lynput:attachGamepad(gamepad)
  -- TODO: More code, this needs to detach previous Lynput gamepad
  self.gpad = gamepad
end


function Lynput:bind(action, commands)
  -- Transforms 1 input to a table
  if type(commands) == "string" then
    local command = commands
    commands = {}
    commands[1] = command
  end -- if only one command was given

  -- Process command
  for _,command in ipairs(commands) do
    -- Is action valid?
    assert(
      _isActionValid(action),
      "Could not bind command->" .. command ..
      -- TODO: Check documentation for valid actions message
	"  to action->" .. action .. ", the action is not valid"
    )
    -- Is command valid?
    local commandValid, state, input = _isCommandValid(command)
    assert(
      commandValid,
      "Could not bind command->" .. command ..
      -- TODO: Check documentation for valid commands message
	"  to action->" .. action .. ", the command is not valid"
    )

    if self[action] == nil then
      self[action] = false
    end -- if action not set
    
    -- TOOD: Remove
    -- -- FIXME: Pressed and released do not work for movement inputs
    -- if not self[action] then
    --   self[action] = {}
    --   self[action].pressed = false
    --   self[action].released = false
    --   self[action].holding = false
    -- end -- if action not set

    self.inputsSet[input] = {}
    self.inputsSet[input][state] = action
  end -- for each command
end


function Lynput:unbind(action, commands)
  -- Transforms 1 command to a table
  if type(commands) == "string" then
    local command = commands
    commands = {}
    commands[1] = command
  end -- if only one command was given

  -- Process command
  for _,command in ipairs(commands) do
    -- Is action set?
    -- FIXME: Exception when indexing nil values are not being handled, fix everywhere
    assert(
      self[action] ~= nil,
      "Could not unbind command->" .. command .. 
	"  to action->" .. action .. ", the action is not set"
    )
    -- Is command set?
    local state, input = string.match(command, "(%w+)%s(.+)")
    assert(
      self.inputsSet[input][state],
      "Could not unbind command->" .. command .. 
	"  to action->" .. action .. ", the command is not set"
    )
    
    self.inputsSet[input][state] = nil
    local inputStates = self.inputsSet[input]
    if not inputStates["press"] and not inputStates["hold"] and not inputStates["release"] then
      self.inputsSet[input] = nil
    end -- if input is not set

    self[action] = false
  end -- for each command
end


function Lynput:unbindAll(action)
  -- Is action set?
  assert(
    self[action] ~= nil,
    "Could not unbind all commands in action->" .. action ..
      ", the action is not set"
  )

  for k,v in pairs(self.inputsSet) do
    for kk,vv in pairs(v) do
      if vv == action then
	self.inputsSet[k][kk] = nil
      end -- if vv == action
    end -- for each input state
  end -- for each input set
  
  self[action] = false
end


function Lynput:removeAction(action)
  -- Is action set?
  assert(
    self[action] ~= nil,
    "Could not remove action->" .. action ..
      ", the action is not being used"
  )
  
  self:unbindAll(action)
  self[action] = nil
end


function Lynput:update()
  -- It's not possible to iterate actions through "self" because it
  -- also contains the inputsSet table
  -- FIXME: Only works if lynput is updated after input processing
  for _,v in pairs(self.inputsSet) do
    for k,vv in pairs(v) do
      if k == "hold" then
	goto continue
      end -- if k == hold

      self[vv] = false
      
      ::continue::
    end -- for each state
  end -- for each input set
end


---------------------------------
-- KEYBOARD CALLBACKS
---------------------------------
function Lynput.onkeypressed(key)
  for _,v in pairs(Lynput.s_lynputs) do
    if v.inputsSet[key] then
      if v.inputsSet[key]["press"] then
	local action = v.inputsSet[key]["press"]
	v[action] = true
      end -- if press_key is set
      if v.inputsSet[key]["hold"] then
	local action = v.inputsSet[key]["hold"]
	v[action] = true
      end -- if hold_key is set      
    end -- if key set
  end -- for each lynput
end


function Lynput.onkeyreleased(key)
  for _,v in pairs(Lynput.s_lynputs) do
    if v.inputsSet[key] then
      if v.inputsSet[key]["release"] then
	local action = v.inputsSet[key]["release"]
	v[action] = true
      end -- if release_key is set
      if v.inputsSet[key]["hold"] then
	local action = v.inputsSet[key]["hold"]
	v[action] = false
      end -- if hold_key is set
    end -- if key is set
  end -- for each lynput
end


--------------------------------------
-- MOUSE CALLBACKS
--------------------------------------
function Lynput.onmousepressed(button)
  -- Translate LÖVE button to Lynput button
  button = Lynput.s_mouseButtons[tostring(button)]
  -- Process button
  for _,v in pairs(Lynput.s_lynputs) do
    if v.inputsSet[button] then
      if v.inputsSet[button]["press"] then
	local action = v.inputsSet[button]["press"]
	v[action] = true
      end -- if press_button is set
      if v.inputsSet[button]["hold"] then
	local action = v.inputsSet[button]["hold"]
	v[action] = true
      end -- if hold_button is set
    end -- if button is set
  end -- for each lynput
end


function Lynput.onmousereleased(button)
    -- Translate LÖVE button to Lynput button
  button = Lynput.s_mouseButtons[tostring(button)]
  -- Process button
  for _,v in pairs(Lynput.s_lynputs) do
    if v.inputsSet[button] then
      if v.inputsSet[button]["release"] then
	local action = v.inputsSet[button]["release"]
	v[action] = true
      end -- if press_button is set
      if v.inputsSet[button]["hold"] then
	local action = v.inputsSet[button]["hold"]
	v[action] = false
      end -- if hold_button is set
    end -- if button is set
  end -- for each lynput
end


---------------------------------------------------
-- GAMEPAD CALLBACKS
---------------------------------------------------
function Lynput.ongamepadpressed(gamepadID, button)
  -- Translate LÖVE button to Lynput button
  button = Lynput.s_gamepadButtons[button]
  -- Process Lynput button
  for _,v in pairs(Lynput.s_lynputs) do
    if Lynput[v.gpad] == gamepadID then
      if v.inputsSet[button] then
	if v.inputsSet[button]["press"] then
	  local action = v.inputsSet[button]["press"]
	  v[action] = true
	end -- if press_button is set
	if v.inputsSet[button]["hold"] then
	  local action = v.inputsSet[button]["hold"]
	  v[action] = true
	end -- if hold_button is set
      end -- if button is set
    end -- if gamepad is set
  end -- for each lynput
end


function Lynput.ongamepadreleased(gamepadID, button)
    -- Translate LÖVE button to Lynput button
  button = Lynput.s_gamepadButtons[button]
  -- Process Lynput button
  for _,v in pairs(Lynput.s_lynputs) do
    if Lynput[v.gpad] == gamepadID then
      if v.inputsSet[button] then
	if v.inputsSet[button]["release"] then
	  local action = v.inputsSet[button]["release"]
	  v[action] = true
	end -- if release_button is set
	if v.inputsSet[button]["hold"] then
	  local action = v.inputsSet[button]["hold"]
	  v[action] = false
	end -- if hold_button is set
      end -- if button is set
    end -- if gamepad is set
  end -- for each lynput
end


function Lynput.ongamepadadded(gamepadID)
  local i = 1
  local gpad = "GPAD_1"

  while Lynput[gpad] do
    if Lynput[gpad] == gamepadID then
      return
    end -- if gamepadID is already assgined
    
    i = i +1
    gpad = "GPAD_" .. i
  end -- while gpad exists

  -- gpad does no exists, so we assign the new gamepad to it
  Lynput[gpad] = gamepadID
end
