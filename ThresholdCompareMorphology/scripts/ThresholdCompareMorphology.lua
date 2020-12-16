--Start of Global Scope---------------------------------------------------------

print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1500 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create("viewer2D1")

local regionDecoration = View.PixelRegionDecoration.create()
regionDecoration:setColor(0, 150, 0, 150)

local textDecoration = View.TextDecoration.create()
textDecoration:setColor(0, 0, 255)
textDecoration:setSize(120)
textDecoration:setPosition(50, 150, 0)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

-- This function does segmentation by thresholding the foreground image only.
-- The found region contains large areas outside the object due to the overlap
-- in intensity range caused by the uneven illumination.
--@directThreshold(img:Image, bg:Image) : Image.PixelRegion, float
local function directThreshold(img)
  local startTime = DateTime.getTimestamp()
  local foundRegion = Image.threshold(img, 0, 165)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

-- This function does segmentation by thresholding the foreground image relative
-- to each corresponding pixel value in the background image.
-- The output region is mainly correct but there are many background pixels
-- included and foreground pixels missed.
--@thresholdCompare(img:Image, bg:Image) : Image.PixelRegion, float
local function thresholdCompare(img, bg)
  local startTime = DateTime.getTimestamp()
  local foundRegion = Image.thresholdCompare(img, bg, 8, false)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

-- This function does segmentation by thresholdCompare. Noise in the
-- background and foreground images is removed by grayscale morphological
-- operations prior to thresholding, providing a clean segmentation.
-- Processing of the background image is not included in the processing
-- time as that can be done once in advance in a real application.
--@preThresholdCleanup(img:Image, bg:Image) : Image.PixelRegion, float
local function preThresholdCleanup(img, bg)
  local bgo = bg:morphology(7, 'OPEN')
  local startTime = DateTime.getTimestamp()
  local imgc = img:morphology(7, 'CLOSE')
  local foundRegion = Image.thresholdCompare(imgc, bgo, 0, false)
  local endTime = DateTime.getTimestamp()

  return foundRegion, (endTime - startTime)
end

-- This function does segmentation by thresholdCompare. Noise in the
-- pixel region is removed by morphological operations after thresholding,
-- providing a clean segmentation.
--@postThresholdCleanup(img:Image, bg:Image) : Image.PixelRegion, float
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
  local imview = viewer:addImage(backgroundIm)
  viewer:addText('BACKGROUND', textDecoration, nil, imview)
  viewer:present()
  Script.sleep(DELAY / 2)

  -- Show foreground image
  viewer:clear()
  imview = viewer:addImage(foregroundIm)
  viewer:addText('FOREGROUND', textDecoration, nil, imview)
  viewer:present()
  Script.sleep(DELAY / 2)

  -- Run different approaches for low contrast segmentation
  local segmentationFunctions = {
    ['directThreshold'] = directThreshold,
    ['thresholdCompare'] = thresholdCompare,
    ['preThresholdCleanup'] = preThresholdCleanup,
    ['postThresholdCleanup'] = postThresholdCleanup
  }
  for name, func in pairs(segmentationFunctions) do
    local foundRegion, time_ms = func(foregroundIm, backgroundIm)
    print(name .. ', time: ' .. tostring(time_ms) .. ' ms')

    viewer:clear()
    imview = viewer:addImage(foregroundIm)
    viewer:addText(name, textDecoration, nil, imview)
    viewer:addPixelRegion(foundRegion, regionDecoration, nil, imview)
    viewer:present()
    Script.sleep(DELAY)
  end
  print('App finished.')
end

--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
