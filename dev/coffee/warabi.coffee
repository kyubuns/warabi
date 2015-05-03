if app.documents.length == 0
  alert('対象のpsdを開いてから実行してください。')
  return

if app.activeDocument.activeLayer.typename != 'LayerSet'
  alert('対象のLayerSetを選択してください。')
  return

targetLayerSet = ''
setup = ->
  preferences.rulerUnits = Units.PIXELS
  targetLayerSet = app.activeDocument.activeLayer

main = ->
  sort()
  createAlpha()
  app.activeDocument.activeLayer = targetLayerSet

sort = ->
  targets = targetLayerSet.artLayers
  blocks = []
  border = UnitValue(2, 'px')
  for layer in targetLayerSet.artLayers
    blocks.push({
      x: layer.bounds[0]
      y: layer.bounds[1]
      w: layer.bounds[2] - layer.bounds[0] + border
      h: layer.bounds[3] - layer.bounds[1] + border
      layer: layer
    })

  packer = new NETXUS.RectanglePacker(activeDocument.width.value, activeDocument.height.value)
  for block in blocks
    coords = packer.findCoords(block.w.value, block.h.value)
    original = [block.x, block.y]
    fix = [UnitValue(coords.x, 'px'), UnitValue(coords.y, 'px')]
    block.layer.translate(fix[0]-original[0], fix[1]-original[1])

createAlpha = ->
  copy = targetLayerSet.duplicate()
  mergedLayer = copy.merge()
  targetAlphaChannel = null
  for channel in activeDocument.channels
    if channel.name == targetLayerSet.name + "_a"
      targetAlphaChannel = channel
  if targetAlphaChannel == null
    targetAlphaChannel = activeDocument.channels.add()
    targetAlphaChannel.name = targetLayerSet.name + "_a"

  selectTransparentArea(mergedLayer)
  activeDocument.selection.store(targetAlphaChannel)
  activeDocument.selection.deselect()
  mergedLayer.remove()

selectTransparentArea = (target) ->
  # http://tiku.io/questions/3467018/setting-selection-to-layer-transparency-channel-using-extendscript-in-photoshop
  app.activeDocument.activeLayer = target
  idChnl = charIDToTypeID( "Chnl" )
  actionSelect = new ActionReference()
  actionSelect.putProperty( idChnl, charIDToTypeID( "fsel" ) )

  actionTransparent = new ActionReference()
  actionTransparent.putEnumerated( idChnl, idChnl, charIDToTypeID( "Trsp" ) )

  actionDesc = new ActionDescriptor()
  actionDesc.putReference( charIDToTypeID( "null" ), actionSelect )
  actionDesc.putReference( charIDToTypeID( "T   " ), actionTransparent )

  executeAction( charIDToTypeID( "setd" ), actionDesc, DialogModes.NO )

setup()
main()
alert('complete!')
