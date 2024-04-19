import { WeatherDefinition, GlobalDefinition, RenderingSettings } from "@/libs/Definition";
import { Cartesian3, PostProcessStage, PostProcessStageComposite, PostProcessStageLibrary } from "cesium";
import AtmosphereCommonFragmentShader from "@/shaders/AtmosphereCommon/fragment.fs.glsl";

import VolumetricCloudFragmentShader from "@/shaders/VolumetricClouds/fragment.fs.glsl";
import { clamp, createFragmentShaderPrefix } from "@/libs/Tool";
const { cloudTop, cloudBase, cloudCover, cloudLayerPosition } = WeatherDefinition;
const { scatteringQuality } = RenderingSettings;
const { realPlanetRadius, planetRadius, atmoRadius } = GlobalDefinition;
class VolumetricCloudEffect {
  target: PostProcessStage;
  blurStage: PostProcessStageComposite;
  currentWindVectorWC: Cartesian3;
  constructor() {
    const fragmentShaderPrefix = createFragmentShaderPrefix(scatteringQuality, true);
    this.currentWindVectorWC = new Cartesian3(100, 0, 0);
    const cloudHeightDifference = cloudTop - cloudBase;
    const baseThickness = cloudHeightDifference * cloudLayerPosition;
    const layer = cloudBase + baseThickness;
    // 云层底部高度
    const cloudBaseRadius = realPlanetRadius + cloudBase;
    // 云层顶部高度
    const cloudTopRadius = cloudBaseRadius + cloudHeightDifference;
    const textureScale = clamp(0.12 * scatteringQuality, 0.25, 1);

    this.target = new PostProcessStage({
      textureScale,
      fragmentShader: fragmentShaderPrefix + AtmosphereCommonFragmentShader + "\n" + VolumetricCloudFragmentShader,
      uniforms: {
        planetRadius,
        realPlanetRadius,
        atmoRadiusSquared: atmoRadius * atmoRadius,
        windVector: this.currentWindVectorWC,
        cloudCover,
        cloudBase,
        cloudTop,
        layerPosition: cloudLayerPosition,
        cloudThickness: cloudHeightDifference,
        baseThickness,
        layer,
        cloudBaseRadius,
        cloudTopRadius,
        // 无法使用vite导入
        noiseTexture: "/images/shaders/noise/bluenoise.png",
      },
      name: "volumetricCloudEffect",
    });

    this.blurStage = PostProcessStageLibrary.createBlurStage();
    this.blurStage.uniforms.delta = 1;
    this.blurStage.uniforms.sigma = 2;
    this.blurStage.uniforms.stepSize = clamp(6 - scatteringQuality, 1, 4);
  }

  update() {
    const cloudHeightDifference = cloudTop - cloudBase;
    const baseThickness = cloudHeightDifference * cloudLayerPosition;
    const layer = cloudBase + baseThickness;
    // 云层底部高度
    const cloudBaseRadius = realPlanetRadius + cloudBase;
    console.log("realPlanetRadius", realPlanetRadius);

    // 云层顶部高度
    const cloudTopRadius = cloudBaseRadius + cloudHeightDifference;
    this.target.uniforms.planetRadius = planetRadius;
    this.target.uniforms.realPlanetRadius = realPlanetRadius;
    this.target.uniforms.cloudBase = cloudBase;
    this.target.uniforms.cloudTop = cloudTop;
    this.target.uniforms.layerPosition = cloudLayerPosition;
    this.target.uniforms.cloudThickness = cloudHeightDifference;
    this.target.uniforms.baseThickness = baseThickness;
    this.target.uniforms.layer = layer;
    this.target.uniforms.cloudBaseRadius = cloudBaseRadius;
    this.target.uniforms.cloudTopRadius = cloudTopRadius;
  }
}

export default VolumetricCloudEffect;
