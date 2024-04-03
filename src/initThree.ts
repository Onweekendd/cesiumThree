import { PerspectiveCamera, Scene, WebGLRenderer } from "three";

function initThree(threeContainer: HTMLDivElement) {
  const camera = new PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 1000000);
  const scene = new Scene();
  const renderer = new WebGLRenderer({
    alpha: true,
    antialias: true,
    logarithmicDepthBuffer: true,
  });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  threeContainer.appendChild(renderer.domElement);

  return { camera, scene, renderer };
}

export default initThree;
