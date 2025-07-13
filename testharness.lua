local pathFinding = {
   currentStep = 0,
   currentLine = 1,
   currentLayer = 1,

   maxStepsPerLineCount = 5,
   maxLinesPerLayerCount = 5,
   maxLayersPerJobCount = 5,
}

local turtle = {
   turnRight = function() print("Turning right") end,
   turnLeft = function() print("Turning left") end,
   down = function() print("Moving down") end,
   forward = function() print("Moving forward") end,
   up = function() print("Moving up") end,
   dig = function() print("Digging forward") return true end,
   digDown = function() print("Digging down") return true end,
   inspectDown = function() return false end,
   inspect = function() return false end
}

function pathFinding:gatherNextBlockData()
   return true
end

function pathFinding:executeNextMove()
   local isEndOfCurrentLine = self.currentStep == self.maxStepsPerLineCount
   local isEndOfLayer = isEndOfCurrentLine and self.currentLine == self.maxLinesPerLayerCount
   local isEndOfJob = isEndOfLayer and self.currentLayer == self.maxLayersPerJobCount
   
   local isTurnRequired = false
   local isSecondTurnRequired = false
   local isLineTurnSequenceInverted =  (self.currentLayer % 2 == 0 and self.currentLine % 2 == 1)
                                       or
                                       (self.currentLayer % 2 == 1 and self.currentLine % 2 == 0)

   if isEndOfCurrentLine then
      self.currentStep = 1
      if isEndOfLayer then
         self.currentLine = 1
         self.currentLayer = self.currentLayer + 1
         turtle.turnRight()
      else
         self.currentLine = self.currentLine + 1
         isSecondTurnRequired = true
      end
      isTurnRequired = true
   end if isTurnRequired then
      if isLineTurnSequenceInverted then
         turtle.turnLeft()
      else
         turtle.turnRight()
      end
   end

   local canMoveNext, blockIsMineable = self:gatherNextBlockData(isEndOfLayer)
   if not canMoveNext and blockIsMineable then
      if not self:mineNextBlock(isEndOfLayer) then
         return false, "Failed to mine block, cannot continue"
      end
   end

   if not isEndOfLayer then
      turtle.forward()
      if not isEndOfCurrentLine then
         self.currentStep = self.currentStep + 1
      end
   else
      turtle.down()
   end

   -- Complete the half turn to line up for the next line if we reached end of line
   -- and already turned
   if isSecondTurnRequired then
      if not isLineTurnSequenceInverted then
         turtle.turnRight()
      else
         turtle.turnLeft()
      end
   end

   return true, nil
end


local moveWasValid = pathFinding:executeNextMove()
while moveWasValid do
   moveWasValid = pathFinding:executeNextMove()
end