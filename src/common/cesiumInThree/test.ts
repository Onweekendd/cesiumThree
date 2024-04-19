const g = typeof window != "undefined" ? window : typeof global != "undefined" ? global : globalThis;
import * as Cesium from "cesium";
g.Cesium = Cesium;
import CesiumMeshVisualizers from "cesiummeshvisualizer";

function init() {
  console.log(CesiumMeshVisualizers);
}

export default init;
