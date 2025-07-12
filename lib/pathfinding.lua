local directions = {
   ["north"] = { axis = "z", direction = -1 },
   ["south"] = { axis = "z", direction = 1 },
   ["west"] = { axis = "x", direction = -1 },
   ["east"] = { axis = "x", direction = 1 },
}

local pathFinding = {}

function pathFinding:gatherNextBlockData(isNextBlockDown)
   local hasBlock, blockData
   if isNextBlockDown then
      hasBlock, blockData = turtle.inspectDown()
   else
      hasBlock, blockData = turtle.inspect()
   end

   local blockName = hasBlock and blockData.name or nil
   local spaceIsEmpty = blockName == nil or blockName == "minecraft:air"
   local isMineable = blockData.tags ~= nil
      and
      (
         blockData.tags["minecraft:mineable/pickaxe"]
         or blockData.tags["minecraft:mineable/axe"]
         or blockData.tags["minecraft:mineable/shovel"]
         or blockData.tags["minecraft:mineable/hoe"]
      )
      or false

   if self.voxelData[self.currentStep] == nil then
      self.voxelData[self.currentStep] = {}
   end
   if self.voxelData[self.currentStep][self.currentLine] == nil then
      self.voxelData[self.currentStep][self.currentLine] = {}
   end
   if self.voxelData[self.currentStep][self.currentLine][self.currentLayer] == nil then
      self.voxelData[self.currentStep][self.currentLine][self.currentLayer] = {}
   end

   self.voxelData[self.currentStep][self.currentLine][self.currentLayer] = {
      blockName = blockName,
      isMineable = isMineable,
      isMined = false
   }

   print(string.format("Step: %s, Line: %s, Layer: %s, Empty: %s, Mineable: %s", self.currentStep, self.currentLine, self.currentLayer, spaceIsEmpty, isMineable))

   return spaceIsEmpty, isMineable
end

function pathFinding:mineNextBlock(isNextBlockDown)
   local isNextBlockAir, nextBlockIsMineable = self:gatherNextBlockData(isNextBlockDown)

   if isNextBlockAir then
      print("Block is air, moving to next")
      return true -- No block to mine, just move
   end
   
   if nextBlockIsMineable then
      print("Block is mineable")
      local wasBlockMined, errorText

      if not isNextBlockDown then
         print("Digging forward")
         wasBlockMined, errorText = turtle.dig("right")
         print(string.format("Mined: %s, Error: %s", wasBlockMined, errorText))
      else
         print("Digging down")
         wasBlockMined, errorText = turtle.digDown("right")
         print(string.format("Mined: %s, Error: %s", wasBlockMined, errorText))
      end

      self.voxelData[self.currentStep][self.currentLine][self.currentLayer].isMined = wasBlockMined

      if not wasBlockMined then
         self.voxelData[self.currentStep][self.currentLine][self.currentLayer].errorText = errorText
         return false
      end
   else
      return false
   end

   return true
end

function pathFinding:executeNextMove()
   local isEndOfCurrentLine = self.currentStep == self.maxStepsPerLineCount
   local isEndOfLayer = isEndOfCurrentLine and self.currentLine == self.maxLinesPerLayerCount
   local isEndOfJob = isEndOfLayer and self.currentLayer == self.maxLayersPerJobCount

   if isEndOfJob then
      return false, "Reached natural end of job, cannot continue"
   end

   local isTurnRequired = false
   local isSecondTurnRequired = false
   if isEndOfCurrentLine then
      self.currentStep = 1

      if isEndOfLayer then
         self.currentLine = 1
         self.currentLayer = self.currentLayer + 1
         turtle.turnRight()
         isSecondTurnRequired = true
      else         
         self.currentLine = self.currentLine + 1
      end
      isTurnRequired = true
   end

   local isLineTurnSequenceInverted =  (self.currentLayer % 2 == 0 and self.currentLine % 2 == 1)
                                       or
                                       (self.currentLayer % 2 == 1 and self.currentLine % 2 == 0)

   if isTurnRequired then
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
      self.currentStep = self.currentStep + 1
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

function pathFinding:getCurrentDirection()
   return self.compass.getFacing()
end

function pathFinding:buildPathHome()
   local isLayerStartInverted = self.currentLayer % 2 == 0
   local isLineStepsInverted = self.currentLine % 2 == 0

   local layersToAscend = self.currentLayer - 1
   local linesToCross = isLayerStartInverted
      and self.maxLinesPerLayerCount - self.currentLine
      or self.currentLine - 1
   local stepsToTake = isLineStepsInverted
      and self.maxStepsPerLineCount - self.currentStep
      or self.currentStep

   return layersToAscend, linesToCross, stepsToTake
end

function pathFinding:getOrientationTurnsForHomeLine()
   local currentDirection = self:getCurrentDirection()
   if directions[currentDirection].axis == directions[self.initialFacing].axis and currentDirection == self.initialFacing then
      return { turtle.turnRight,  turtle.turnRight }
   end

   if directions[currentDirection].direction + directions[self.initialFacing].direction ~= 0 then
      return { turtle.turnLeft }
   end

   return { turtle.turnRight }
end

function pathFinding:getOrientationTurnsToCrossLinesToHomeRun()
   local currentDirection = self:getCurrentDirection()
   if directions[currentDirection].axis == directions[self.initialFacing].axis then
      if currentDirection == self.initialFacing then
         return { turtle.turnLeft }
      else
         return { turtle.turnRight }
      end
   end
   
   if directions[currentDirection].direction + directions[self.initialFacing].direction ~= 0 then
      return { turtle.turnRight,  turtle.turnRight }
   end
end

function pathFinding:moveToHome()
   local layersToAscend, linesToCross, stepsToTake = self:buildPathHome()

   for _ = 1, layersToAscend do
      turtle.up()
   end

   if linesToCross > 0 then
      for _, turn in ipairs(self:getOrientationTurnsToCrossLinesToHomeRun()) do
         turn()
      end
      for _ = 1, linesToCross do
         turtle.forward()
      end
   end

   for _, turn in ipairs(self:getOrientationTurnsForHomeLine()) do
      turn()
   end
   for _ = 1, stepsToTake do
      turtle.forward()
   end

   turtle.turnRight()
   turtle.turnRight()
end

function pathFinding:init(endPosition)
   if self.initialised then
      error("Pathfinding already initialised")
   end

   self.compass = peripheral.find("compass")

   self.initialised = true
   self.initialFacing = self:getCurrentDirection()
   self.startPosition = { x = 0, y = 0, z = 0 }
   self.endPositionExpected = endPosition
   self.endPositionActual = nil

   self.currentStep = 0
   self.currentLine = 1
   self.currentLayer = 1
   self.lineStepCoordinate = self.initialFacing[self.initialFacing]

   if self.lineStepCoordinate == "x" then
      self.maxStepsPerLineCount = endPosition.x - self.startPosition.x
      self.maxLinesPerLayerCount = endPosition.z - self.startPosition.z
   else
      self.maxStepsPerLineCount = endPosition.z - self.startPosition.z
      self.maxLinesPerLayerCount = endPosition.x - self.startPosition.x
   end

   self.maxLayersPerJobCount = endPosition.y - self.startPosition.y

   self.voxelData = {} -- 3 dimensional table to hold voxel data
end

return pathFinding