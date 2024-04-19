import { Cartesian3, Color } from "cesium";

const WeatherDefinition = {
  cloudCover: 0,
  cloudBase: 6500,
  cloudTop: 3e3,
  cloudThickness: 4e3,
  cloudCoverThickness: 200,
  cloudLayerPosition: 0.1,
  windVector: new Cartesian3(100, 0, 0),
};

const GlobalDefinition = {
  color: Color.fromCssColorString("#b6d3f5ff"),
  dayColor: Color.fromCssColorString("#b6d3f5ff"),
  nightColor: Color.fromCssColorString("#e0773dff"),
  brightness: 1,
  globeLoaded: false,
  updatePeriod: 1e3,
  cloudsUpdatePeriod: 6e5,
  cloudLayerPosition: 0.1,
  planetRadius: 6361e3,
  atmoRadius: 6472e3,
  realPlanetRadius: 6371e3,
};

const RenderingSettings = {
  volumetricClouds: true,
  advancedAtmosphere: true,
  scatteringQuality: 7,
  globeLighting: true,
  dropShadow: false,
};

const DEGREES_TO_RAD = Math.PI / 180;
const RAD_TO_DEGREES = 180 / Math.PI;

function updateGlobalDefinitionByNewRadius(newRadius: number) {
  GlobalDefinition.planetRadius = newRadius - 1e4;
  GlobalDefinition.atmoRadius = GlobalDefinition.planetRadius + 111e3;
  GlobalDefinition.realPlanetRadius = newRadius;
}

export {
  DEGREES_TO_RAD,
  RAD_TO_DEGREES,
  WeatherDefinition,
  GlobalDefinition,
  RenderingSettings,
  updateGlobalDefinitionByNewRadius,
};
