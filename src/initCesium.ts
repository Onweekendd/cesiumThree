import { ShadowMode, Viewer } from "cesium";

function initCesium(cesiumContainer: HTMLDivElement) {
  console.log(cesiumContainer);

  const viewer = new Viewer(cesiumContainer, {
    useDefaultRenderLoop: false,
    contextOptions: {
      webgl: {
        alpha: false,
        antialias: true,
        preserveDrawingBuffer: true,
        failIfMajorPerformanceCaveat: false,
        depth: true,
        stencil: false,
      },
    },
    targetFrameRate: 60,
    animation: false,
    baseLayerPicker: false,
    geocoder: false,
    timeline: false,
    orderIndependentTranslucency: true,
    terrainShadows: ShadowMode.DISABLED,
    // 自定义属性
    automaticallyTrackDataSourceClocks: false,
  });
  return viewer;
}

export default initCesium;
