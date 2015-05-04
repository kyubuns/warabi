targetLayerSet = ''
border = null

setup = ->
  border = UnitValue(2, 'px')
  preferences.rulerUnits = Units.PIXELS

  if app.documents.length == 0
    alert('対象のpsdを開いてから実行してください。')
    return false

  if app.activeDocument.activeLayer.typename == 'LayerSet'
    targetLayerSet = app.activeDocument.activeLayer
  else
    if app.activeDocument.activeLayer.parent.typename == 'LayerSet'
      targetLayerSet = app.activeDocument.activeLayer.parent
    else
      alert('対象のLayerSetを選択してください。')
      return false

  return true

main = ->
  prevActiveLayer = app.activeDocument.activeLayer
  sort()
  createAlpha()
  app.activeDocument.activeLayer = prevActiveLayer

sort = ->
  blocks = for layer in targetLayerSet.artLayers when layer.visible
    {
      x: layer.bounds[0]
      y: layer.bounds[1]
      w: layer.bounds[2] - layer.bounds[0] + border
      h: layer.bounds[3] - layer.bounds[1] + border
      layer: layer
    }

  packer = new NETXUS.RectanglePacker(activeDocument.width.value, activeDocument.height.value)
  for block in blocks
    coords = packer.findCoords(block.w.value, block.h.value)
    block.layer.translate(
      UnitValue(coords.x, 'px') - block.x,
      UnitValue(coords.y, 'px')-block.y
    )

createAlpha = ->
  targetAlphaChannel = findOrCreateAlphaChannel(targetLayerSet.name + "_a")

  mergedLayer = targetLayerSet.duplicate().merge()
  selectTransparentArea(mergedLayer)
  activeDocument.selection.store(targetAlphaChannel)
  activeDocument.selection.deselect()
  mergedLayer.remove()

findOrCreateAlphaChannel = (layerName) ->
  target = null
  for channel in activeDocument.channels
    if channel.name == layerName
      target = channel
  if target == null
    target = activeDocument.channels.add()
    target.name = layerName
  target

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

if setup()
  main()
