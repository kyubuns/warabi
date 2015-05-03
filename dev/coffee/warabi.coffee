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

setup()
main()
alert('complete!')
