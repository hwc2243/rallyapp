/// Calculates the calibration factor that makes an existing odometer reading
/// match a measured official distance.
///
/// [currentAppDistance] and [measuredDistance] must use the same display unit.
double calculateNewFactor({
  required double currentFactor,
  required double measuredDistance,
  required double currentAppDistance,
}) {
  return currentFactor * (measuredDistance / currentAppDistance);
}
