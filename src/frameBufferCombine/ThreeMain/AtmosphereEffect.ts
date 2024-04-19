import { Cartesian3, Cartographic, Color, PostProcessStage, PostProcessStageComposite, Viewer } from "cesium";
import AtmosphereFragmentShader from "@/shaders/Atmosphere/fragment.fs.glsl";
import AtmosphereCommonFragmentShader from "@/shaders/AtmosphereCommon/fragment.fs.glsl";
import { clamp } from "@/libs/Tool";
import {
  GlobalDefinition,
  WeatherDefinition,
  RenderingSettings,
  DEGREES_TO_RAD,
  updateGlobalDefinitionByNewRadius,
} from "@/libs/Definition";
const { planetRadius, color, atmoRadius, realPlanetRadius } = GlobalDefinition;
import { createFragmentShaderPrefix } from "@/libs/Tool";
import VolumetricCloudEffect from "./VolumetricCloudEffect";
const { cloudCover, cloudTop, cloudBase, windVector, cloudLayerPosition } = WeatherDefinition;

class AtmosphereEffect {
  target: PostProcessStage;
  postProcessingStages?: PostProcessStageComposite;
  volumetricCloudEffect?: VolumetricCloudEffect;
  volumetricCloudEnable: boolean;
  constructor(volumetricCloudEnable: boolean) {
    this.volumetricCloudEnable = volumetricCloudEnable;
    const fragmentShaderPrefix = createFragmentShaderPrefix(
      RenderingSettings.scatteringQuality,
      this.volumetricCloudEnable,
    );

    const cloudHeightDifference = cloudTop - cloudBase;
    const baseThickness = cloudHeightDifference * cloudLayerPosition;
    const layer = cloudBase + baseThickness;
    // 云层底部高度
    const cloudBaseRadius = realPlanetRadius + cloudBase;
    // 云层顶部高度
    const cloudTopRadius = cloudBaseRadius + cloudHeightDifference;

    this.target = new PostProcessStage({
      fragmentShader: fragmentShaderPrefix + AtmosphereCommonFragmentShader + "\n" + AtmosphereFragmentShader,
      uniforms: {
        planetRadius,
        realPlanetRadius,
        atmoRadiusSquared: atmoRadius ** 2,
        cloudCover: cloudCover,
        cloudBase,
        cloudTop,
        layerPosition: cloudLayerPosition,
        cloudThickness: cloudHeightDifference,
        baseThickness,
        layer,
        cloudBaseRadius,
        cloudTopRadius,
        windVector,
      },
      name: "atmosphereEffect",
    });

    if (this.volumetricCloudEnable) {
      this.addVolumetricCloud();
    }
  }

  addTo(viewer: Viewer) {
    if (this.volumetricCloudEnable && this.postProcessingStages) {
      viewer.scene.postProcessStages.add(this.postProcessingStages);
      viewer.scene.postRender.addEventListener(() => this.update(viewer));
    } else {
      viewer.scene.postProcessStages.add(this.target);
      viewer.scene.postRender.addEventListener(() => this.update(viewer));
    }
  }

  addVolumetricCloud() {
    this.target.uniforms.volumetricCloudsTexture = "volumetricClouds";
    this.volumetricCloudEffect = new VolumetricCloudEffect();
    this.postProcessingStages = new PostProcessStageComposite({
      inputPreviousStageTexture: false,
      stages: [
        new PostProcessStageComposite({
          inputPreviousStageTexture: true,
          stages: [this.volumetricCloudEffect.target, this.volumetricCloudEffect.blurStage],
          name: "volumetricClouds",
        }),
        this.target,
      ],
    });
    console.log(this.postProcessingStages);
  }

  updateAtmosphere = (viewer: Viewer) => {
    const cameraPositionCartographic = viewer.camera.positionCartographic;
    const cameraWG84 = viewer.scene.globe.ellipsoid.cartographicToCartesian(
      new Cartographic(
        cameraPositionCartographic.longitude * DEGREES_TO_RAD,
        cameraPositionCartographic.latitude * DEGREES_TO_RAD,
        0,
      ),
    );
    // 相机到球心距离
    const newRadius = Cartesian3.magnitude(cameraWG84);
    console.log("newRadius", newRadius);

    updateGlobalDefinitionByNewRadius(newRadius);

    const cloudHeightDifference = cloudTop - cloudBase;
    const baseThickness = cloudHeightDifference * cloudLayerPosition;
    const layer = cloudBase + baseThickness;
    // 云层底部高度
    const cloudBaseRadius = realPlanetRadius + cloudBase;
    // 云层顶部高度
    const cloudTopRadius = cloudBaseRadius + cloudHeightDifference;

    this.target.uniforms.planetRadius = planetRadius;
    this.target.uniforms.realPlanetRadius = realPlanetRadius;
    this.target.uniforms.atmoRadiusSquared = atmoRadius ** 2;
    this.target.uniforms.realPlanetRadius = realPlanetRadius;
    this.target.uniforms.cloudCover = cloudCover;
    this.target.uniforms.cloudBase = cloudBase;
    this.target.uniforms.cloudTop = cloudTop;
    this.target.uniforms.layerPosition = cloudLayerPosition;
    this.target.uniforms.cloudThickness = cloudHeightDifference;
    this.target.uniforms.baseThickness = baseThickness;
    this.target.uniforms.layer = layer;
    this.target.uniforms.cloudBaseRadius = cloudBaseRadius;
    this.target.uniforms.cloudTopRadius = cloudTopRadius;
  };

  updateWithoutCloud = (viewer: Viewer) => {
    if (viewer.camera.positionCartographic.height > 20000) {
      this.target.enabled = false;
      viewer.scene.skyAtmosphere.show = true;
    } else {
      this.target.enabled = true;
      viewer.scene.skyAtmosphere.show = false;
    }
  };

  updateWithCloud = (viewer: Viewer) => {
    if (!this.postProcessingStages) return;
    if (viewer.camera.positionCartographic.height > 20000) {
      if (this.postProcessingStages.enabled !== false) {
        this.postProcessingStages.enabled = false;
        viewer.scene.skyAtmosphere.show = true;
      }
    } else {
      if (this.postProcessingStages.enabled !== true) {
        this.postProcessingStages.enabled = true;
        viewer.scene.skyAtmosphere.show = false;
      }
    }
  };

  update = (viewer: Viewer) => {
    if (this.volumetricCloudEnable) {
      this.updateWithCloud(viewer);
      this.updateAtmosphere(viewer);
      this.volumetricCloudEffect!.update();
    } else {
      this.updateWithoutCloud(viewer);
      this.updateAtmosphere(viewer);
    }
  };
}

export default AtmosphereEffect;
