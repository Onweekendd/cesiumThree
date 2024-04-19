import { Cartesian3, Viewer } from "cesium";

function initCesium(cesiumContainer: HTMLDivElement) {
  console.log(cesiumContainer);

  const viewer = new Viewer(cesiumContainer, {});
  viewer.scene.globe.depthTestAgainstTerrain = true;
  const pos = {
    x: 404039.9361591999,
    y: 5606622.599864139,
    z: 3016103.1971778427,
  };
  // viewer.camera.flyTo({
  //   destination: new Cartesian3(pos.x, pos.y, pos.z),
  //   duration: 0,
  // });
  // viewer.scene.camera.setView({
  //   orientation: {
  //     heading: 3.231480277065711,
  //     pitch: -0.17330830717531587,
  //     roll: 0.00007049006672854574,
  //   },
  // });
  return viewer;
}

export default initCesium;
