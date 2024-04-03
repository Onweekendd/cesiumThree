import { Object3D } from "three";

class _3DObject {
  mesh: Object3D | undefined;
  minWGS84: number[] | undefined;
  maxWGS84: number[] | undefined;
  constructor(mesh: Object3D | undefined, minWGS84: number[] | undefined, maxWGS84: number[] | undefined) {
    this.mesh = mesh;
    this.minWGS84 = minWGS84;
    this.maxWGS84 = maxWGS84;
  }
}

export default _3DObject;
