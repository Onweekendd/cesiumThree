import initCesium from "./initCesium";
import initThree from "./initThree";
import { maxWGS84, minWGS84 } from "../../common/WGS84";
import { Cartesian3, Color, Math as CesiumMath } from "cesium";
import _3DObject from "../../common/object3D";
import {
  MeshNormalMaterial,
  DoubleSide,
  Vector2,
  LatheGeometry,
  Mesh,
  Group,
  DodecahedronGeometry,
  Vector3,
} from "three";

function mulityCanvas() {
  const cesiumContainer = document.getElementById("CesiumContainer") as HTMLDivElement;
  const threeContainer = document.getElementById("ThreeContainer") as HTMLDivElement;

  const _3DObjectList: _3DObject[] = [];
  const viewer = initCesium(cesiumContainer);
  const center = Cartesian3.fromDegrees((minWGS84[0] + maxWGS84[0]) / 2, (minWGS84[1] + maxWGS84[1]) / 2, 20000);

  viewer.camera.flyTo({
    destination: center,
    orientation: {
      heading: CesiumMath.toRadians(0),
      pitch: CesiumMath.toRadians(-60),
      roll: CesiumMath.toRadians(0),
    },
    duration: 0,
  });

  viewer.entities.add(createPolygonInCesium());

  const { camera, scene, renderer } = initThree(threeContainer);

  const latheMesh = createLatheInThree();
  scene!.add(latheMesh);
  const _LatheObject = new _3DObject(latheMesh, minWGS84, maxWGS84);
  _3DObjectList.push(_LatheObject);

  const dodecahedron = createDodecahedronInThree();
  scene!.add(dodecahedron);
  const _DodecahedronObject = new _3DObject(dodecahedron, minWGS84, maxWGS84);
  _3DObjectList.push(_DodecahedronObject);

  function Cartesian3ToVector3(cartesian3: Cartesian3) {
    return new Vector3(cartesian3.x, cartesian3.y, cartesian3.z);
  }

  _3DObjectList.forEach((_3DObjectInstance) => {
    const minWGS84 = _3DObjectInstance.minWGS84 ?? [0, 0];
    const maxWGS84 = _3DObjectInstance.maxWGS84 ?? [0, 0];

    // 坐标原点
    const objectCenter = Cartesian3.fromDegrees((minWGS84[0] + maxWGS84[0]) / 2, (minWGS84[1] + maxWGS84[1]) / 2);

    // 正前方向
    const centerHigh = Cartesian3ToVector3(
      Cartesian3.fromDegrees((minWGS84[0] + maxWGS84[0]) / 2, (minWGS84[1] + maxWGS84[1]) / 2, 1),
    );

    const bottomLeft = Cartesian3ToVector3(Cartesian3.fromDegrees(minWGS84[0], minWGS84[1]));

    const topLeft = Cartesian3ToVector3(Cartesian3.fromDegrees(minWGS84[0], maxWGS84[1]));

    // 上部朝向
    const latDir = new Vector3().subVectors(bottomLeft, topLeft).normalize();

    _3DObjectInstance.mesh?.position.copy(objectCenter);
    console.log(_3DObjectInstance.mesh?.position);

    _3DObjectInstance.mesh?.lookAt(centerHigh);
    _3DObjectInstance.mesh?.up.copy(latDir);
  });

  function loop() {
    requestAnimationFrame(loop);
    renderCesium();
    renderThree();
  }
  function renderCesium() {
    viewer.render();
  }
  function renderThree() {
    // @ts-expect-error  存在fov
    camera.fov = CesiumMath.toDegrees(viewer.camera.frustum.fovy);
    camera.updateProjectionMatrix();
    const cameraVM = viewer.camera.viewMatrix;
    const cameraIVM = viewer.camera.inverseViewMatrix;

    camera.matrixAutoUpdate = false;
    // cesium中的 viewMatrix 和 inverseViewMatrix 对应 three中的 matrixWorldInverse 和 matrixWorld
    // Cesium（列主序）  Three.js（行主序）  赋值前需要做转置
    camera.matrixWorld.set(
      cameraIVM[0],
      cameraIVM[4],
      cameraIVM[8],
      cameraIVM[12],
      cameraIVM[1],
      cameraIVM[5],
      cameraIVM[9],
      cameraIVM[13],
      cameraIVM[2],
      cameraIVM[6],
      cameraIVM[10],
      cameraIVM[14],
      cameraIVM[3],
      cameraIVM[7],
      cameraIVM[11],
      cameraIVM[15],
    );

    camera.matrixWorldInverse.set(
      cameraVM[0],
      cameraVM[4],
      cameraVM[8],
      cameraVM[12],
      cameraVM[1],
      cameraVM[5],
      cameraVM[9],
      cameraVM[13],
      cameraVM[2],
      cameraVM[6],
      cameraVM[10],
      cameraVM[14],
      cameraVM[3],
      cameraVM[7],
      cameraVM[11],
      cameraVM[15],
    );

    const width = threeContainer!.clientWidth;
    const height = threeContainer!.clientHeight;
    const aspect = width / height;
    camera.aspect = aspect;
    camera.updateProjectionMatrix();
    renderer.render(scene, camera);
  }

  loop();
}

function createPolygonInCesium() {
  return {
    name: "Polygon",
    polygon: {
      hierarchy: Cartesian3.fromDegreesArray([
        minWGS84[0],
        minWGS84[1],
        maxWGS84[0],
        minWGS84[1],
        maxWGS84[0],
        maxWGS84[1],
        minWGS84[0],
        maxWGS84[1],
      ]),
      material: Color.RED.withAlpha(0.2),
    },
  };
}

function createLatheInThree() {
  const doubleSideMaterial = new MeshNormalMaterial({
    side: DoubleSide,
  });
  const segments = 10;
  const points = [];
  for (let i = 0; i < segments; i++) {
    points.push(new Vector2(Math.sin(i * 0.2) * segments + 5, (i - 5) * 2));
  }
  const geometry = new LatheGeometry(points);
  const latheMesh = new Mesh(geometry, doubleSideMaterial);
  latheMesh.scale.set(1500, 1500, 1500); //scale object to be visible at planet scale
  latheMesh.position.z += 15000.0; // translate "up" in js space so the "bottom" of the mesh is the handle
  latheMesh.rotation.x = Math.PI / 2; // rotate mesh for Cesium's Y-up system
  const latheMeshYup = new Group();
  latheMeshYup.add(latheMesh);
  return latheMeshYup;
}

function createDodecahedronInThree() {
  const geometry = new DodecahedronGeometry();
  const dodecahedronMesh = new Mesh(geometry, new MeshNormalMaterial());
  dodecahedronMesh.scale.set(5000, 5000, 5000);
  dodecahedronMesh.position.z += 15000.0;
  dodecahedronMesh.rotation.x = Math.PI / 2;
  const dodecahedronMeshYup = new Group();
  dodecahedronMeshYup.add(dodecahedronMesh);

  return dodecahedronMeshYup;
}

export default mulityCanvas;
