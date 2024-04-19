precision highp float;
uniform sampler2D colorTexture;
uniform sampler2D depthTexture;

#ifdef VOLUMETRIC_CLOUDS
uniform sampler2D volumetricCloudsTexture;
#endif

in vec2 v_textureCoordinates;

void main() {
  vec4 color = texture(colorTexture, v_textureCoordinates);
  vec4 rawDepthColor = texture(depthTexture, v_textureCoordinates);
  // depth packing algo appears to be buggy on mobile so only use the most significant element for now
  float depth = rawDepthColor.r;

  vec4 positionEC = czm_windowToEyeCoordinates(gl_FragCoord.xy, depth);
  vec4 worldCoordinate = czm_inverseView * positionEC;
  vec3 vWorldPosition = worldCoordinate.xyz / worldCoordinate.w;
  vec3 posToEye = vWorldPosition - czm_viewerPositionWC;
  vec3 direction = normalize(posToEye);
  vec3 lightDirection = normalize(czm_sunPositionWC);
  float distance = length(posToEye);
  float elevation;

  #ifdef RETRO
  if(depth >= 0.9) {
    out_FragColor = color;
    return;
  }
  #endif

  if(depth >= 1.0) {
    elevation = length(czm_viewerPositionWC) - (realPlanetRadius);
    // max out the distance when looking at the sky to avoid clamp/arc artefact
    distance = max(distance, 10000000.0);
  } else {
    elevation = length(vWorldPosition) - (realPlanetRadius);
  }

  // float fragFogDensity;
  // fragFogDensity = clamp((volumetricFogTop - elevation) / (volumetricFogTop - volumetricFogBottom), 0.0, 1.0) * volumetricFogDensity * depth; // volumetric
  // color = mix(color, vec4(czm_lightColor, 1.0), clamp(fragFogDensity, 0.0, 1.0));

  #if defined(VOLUMETRIC_CLOUDS)
  float depthMaskDistance = 0.5;
  if(length(czm_viewerPositionWC) < cloudBaseRadius) {
    depthMaskDistance = 0.9; // try to include distant trees and object in the mask
  }
    #if defined(CLOUD_SHADOWS)
  float baseDistance = cloudBaseRadius + baseThickness;
  if(depth < 1.0 && czm_lightColor.z > 0.15 && length(vWorldPosition) < baseDistance) {
    vec3 wind = windVector * czm_frameNumber * windSpeedRatio;
    float mask = 1.0;
    vec2 toClouds = raySphereIntersect(vWorldPosition, -lightDirection, baseDistance);
    vec3 position = vWorldPosition + (-lightDirection * toClouds.x);
    float hr;
    float dens = cloudDensity(position, wind, 0, hr);
    mask = clamp(1.0 - dens, 0.2, 1.0);
    color *= mask;
  }
    #endif
  #endif

  #ifdef ADVANCED_ATMOSPHERE
  vec4 atmosphereColor = calculate_scattering(czm_viewerPositionWC, direction, distance, lightDirection);
  color = atmosphereColor + color * (1.0 - atmosphereColor.a);

    #ifdef VOLUMETRIC_CLOUDS
  vec4 clouds = texture(volumetricCloudsTexture, v_textureCoordinates);
  clouds.rgb *= 3.0;
  color = mix(color, clouds, clouds.a * clouds.a * clamp((depth - depthMaskDistance) * 100.0, 0.0, 1.0));
    #endif

  float exposure = 1.2;
  color = vec4(1.0 - exp(-exposure * color));
  #endif

  out_FragColor = color;
}