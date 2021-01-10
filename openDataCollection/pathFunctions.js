function findY(path, x) {
  var pathLength = path.getTotalLength()
  var start = 0
  var end = pathLength
  var target = (start + end) / 2

  // Ensure that x is within the range of the path
  x = Math.max(x, path.getPointAtLength(0).x)
  x = Math.min(x, path.getPointAtLength(pathLength).x)

  // Walk along the path using binary search 
  // to locate the point with the supplied x value
  while (target >= start && target <= pathLength) {
    var pos = path.getPointAtLength(target)

    // use a threshold instead of strict equality 
    // to handle javascript floating point precision
    if (Math.abs(pos.x - x) < 0.001) {
      return pos.y
    } else if (pos.x > x) {
      end = target
    } else {
      start = target
    }
    target = (start + end) / 2
  }
}