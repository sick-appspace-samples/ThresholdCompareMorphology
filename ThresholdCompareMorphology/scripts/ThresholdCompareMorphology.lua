
--Start of Global Scope---------------------------------------------------------

print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1500 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create()

local regionDecoration = View.PixelRegionDecoration.create():setColor(0, 150, 0, 150)

local textDecoration = View.TextDecoration.create()
textDecoration:setColor(0, 0, 255):setSize(120):setPosition(50, 150, 0)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

--- This function does segmentation by thresholding the foreground image only.
--- The found region contains large areas outside the object due to the overlap
--- in intensity range caused by the uneven illumination.
---@param img Image
---@return Image.PixelRegion
---@return integer
local function directThreshold(img)
  local startTime = DateTime.getTimestamp()
  local foundRegion = Image.threshold(img, 0, 165)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

--- This function does segmentation by thresholding the foreground image relative
--- to each corresponding pixel value in the background image.
--- The output region is mainly correct but there are many background pixels
--- included and foreground pixels missed.
---@param img Image
---@param bg Image
---@return Image.PixelRegion
---@return integer
local function thresholdCompare(img, bg)
  local startTime = DateTime.getTimestamp()
  local foundRegion = Image.thresholdCompare(img, bg, 8, false)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

--- This function does segmentation by thresholdCompare. Noise in the
--- background and foreground images is removed by grayscale morphological
--- operations prior to thresholding, providing a clean segmentation.
--- Processing of the background image is not included in the processing
--- time as that can be done once in advance in a real application.
---@param img Image
---@param bg Image
---@return Image.PixelRegion
---@return integer
local function preThresholdCleanup(img, bg)
  local bgo = bg:morphology(7, 'OPEN')
  local startTime = DateTime.getTimestamp()
  local imgc = img:morphology(7, 'CLOSE')
  local foundRegion = Image.thresholdCompare(imgc, bgo, 0, false)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

--- This function does segmentation by thresholdCompare. Noise in the
--- pixel region is removed by morphological operations after thresholding,
--- providing a clean segmentation.
---@param img Image
---@param bg Image
---@return Image.PixelRegion
---@return integer
local function postThresholdCleanup(img, bg)
  local startTime = DateTime.getTimestamp()
  -- Threshold relative to background image
  local foundRegion = Image.thresholdCompare(img, bg, 6, false)
  foundRegion = foundRegion:erode(5):dilate(5)
  foundRegion = foundRegion:dilate(25):erode(25)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

local function main()
  -- Load images
  local backgroundIm = Image.load('resources/BackgroundImage.bmp')
  local foregroundIm = Image.load('resources/ObjectImage.bmp')

  -- Show background image
  viewer:clear()
  viewer:addImage(backgroundIm)
  viewer:addText('BACKGROUND', textDecoration)
  viewer:present()
  Script.sleep(DELAY / 2)

  -- Show foreground image
  viewer:clear()
  viewer:addImage(foregroundIm)
  viewer:addText('FOREGROUND', textDecoration)
  viewer:present()
  Script.sleep(DELAY / 2)

  -- Run different approaches for low contrast segmentation
  local segmentationFunctions = {
    directThreshold,
    thresholdCompare,
    preThresholdCleanup,
    postThresholdCleanup
  }
  local segmentationFunctionNames = {
    'directThreshold',
    'thresholdCompare',
    'preThresholdCleanup',
    'postThresholdCleanup'}
  for i, func in ipairs(segmentationFunctions) do
    local foundRegion, time_ms = func(foregroundIm, backgroundIm)
    local name = segmentationFunctionNames[i]
    print(name .. ', time: ' .. tostring(time_ms) .. ' ms')

    viewer:clear()
    viewer:addImage(foregroundIm)
    viewer:addText(name, textDecoration)
    viewer:addPixelRegion(foundRegion, regionDecoration)
    viewer:present()
    Script.sleep(DELAY)
  end
  print('App finished.')
end

--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
