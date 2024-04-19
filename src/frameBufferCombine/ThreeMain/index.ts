import {
  Cartesian3,
  Cartesian4,
  Color,
  PostProcessStage,
  PostProcessStageComposite,
  createWorldTerrainAsync,
} from "cesium";
import initCesium from "./initCesium";
import AtmosphereEffect from "./AtmosphereEffect";

async function frameBufferCombine() {
  const cesiumContainer = document.getElementById("CesiumContainer") as HTMLDivElement;

  const viewer = initCesium(cesiumContainer);
  const worldTerrainProvider = await createWorldTerrainAsync();
  viewer.terrainProvider = worldTerrainProvider;

  const atmosphereEffect = new AtmosphereEffect(true);
  atmosphereEffect.addTo(viewer);
}

export default frameBufferCombine;
