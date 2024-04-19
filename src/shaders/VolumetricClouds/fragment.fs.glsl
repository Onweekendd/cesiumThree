precision highp float;
uniform sampler2D noiseTexture;
in vec2 v_textureCoordinates;
vec3 skyAmbientColor = vec3(0.705, 0.850, 0.952); //0.219, 0.380, 0.541
vec3 groundAmbientColor = vec3(0.741, 0.898, 0.823); //0.639, 0.858, 0.721
float distanceQualityR = 0.00005; // LOD/quality ratio
float minDistance = 10.0; // avoid cloud in cockpit
#undef PRIMARY_STEPS
#undef LIGHT_STEPS
#define PRIMARY_STEPS 1
#define LIGHT_STEPS 0

vec4 calculate_clouds(
    vec3 start,
    vec3 dir,
    float maxDistance,
    vec3 light_dir,
    vec3 wind
) {
    vec4 cloud = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 toTop = raySphereIntersect(start, dir, cloudTopRadius);
    vec2 toCloudBase = raySphereIntersect(start, dir, cloudBaseRadius);
    float startHeight = length(start) - realPlanetRadius;
    float absoluteMaxDistance = CLOUDS_MAX_VIEWING_DISTANCE;
    float tmin = minDistance;
    float tmax = maxDistance;

    if(startHeight > cloudTop) {
        if(toTop.x < 0.0)
            return vec4(0.0); // no intersection with cloud layer
        tmin = toTop.x;
        if(toCloudBase.x > 0.0) {
            tmax = min(toCloudBase.x, maxDistance);
        } else {
            tmax = min(toTop.y, maxDistance);
        }
    } else if(startHeight < cloudBase) {
        tmin = toCloudBase.y;
        tmax = min(toTop.y, maxDistance);
    } else {
        if(toCloudBase.x > 0.0) {
            tmax = min(toCloudBase.x, maxDistance);
        } else {
            tmax = min(toTop.y, maxDistance);
        }
    }

    tmin = max(tmin, minDistance);
    tmax = min(tmax, absoluteMaxDistance);

    if(tmax < tmin)
        return vec4(0.0); // object obstruction

    float rayLength = tmax - tmin;
    float longMarchStep = rayLength / float(MAXIMUM_CLOUDS_STEPS);
    longMarchStep = max(longMarchStep, CLOUDS_MARCH_STEP);

    float shortMarchStep = CLOUDS_DENS_MARCH_STEP;
    float numberApproachSteps = (CLOUDS_MARCH_STEP / CLOUDS_DENS_MARCH_STEP) * 2.0;
    float ditherAmount = texture(noiseTexture, mod(gl_FragCoord.xy / 512.0, 1.0)).r * 2.0 - 1.0;
    float ditherDistance = ditherAmount * shortMarchStep;
    float distance = tmin + ditherDistance;
    float dens = 0.0;
    float marchStep;
    float distanceToFirstCloud = 0.0;
    float lastDensity;
    float gInScattering = 0.9;
    float gOutScattering = 0.0;
    float kInScattering = 0.99;
    float dotLightRay = dot(dir, light_dir);
    float inScattering = Schlick(kInScattering, dotLightRay); //HenyeyGreenstein(gInScattering, dotLightRay);
    float outScattering = isotropic(); //HenyeyGreenstein(gOutScattering, dotLightRay);
    float sunScatteringPhase = mix(outScattering, inScattering, dotLightRay);
    float ambientScatteringPhase = isotropic();
    bool inCloud = false;
    bool rayComplete = false;
    float stepsBeforeExitingCloud = 0.0;

    // 在这里做步进
    for(int i = 0; i < MAXIMUM_CLOUDS_STEPS; i++) {
        vec3 position = start + dir * distance;
        float depth = distance / CLOUDS_MAX_VIEWING_DISTANCE;
        int qualityRatio = int(distance * distanceQualityR);
        int lod = CLOUDS_MAX_LOD - qualityRatio;
        float heightRatio;

        if(inCloud == true) {
            marchStep = shortMarchStep;
        } else {
            marchStep = longMarchStep;
            lod = 0;
        }

        dens = cloudDensity(position, wind, lod, heightRatio);

        if(dens > 0.01) {
            if(inCloud != true) {
                inCloud = true;
                stepsBeforeExitingCloud = numberApproachSteps;
                distance = clamp(distance - CLOUDS_MARCH_STEP, tmin, tmax); // take one step back
                continue;
            }

            float deltaDens = clamp((dens - lastDensity) * 10.0, -1.0, 1.0);
            float lighting = (abs(deltaDens - dotLightRay) / 2.0) * clamp((heightRatio - 0.02) * 20.0, 0.5, 1.0);
            lastDensity = dens;
            float scatteringCoeff = 0.15 * dens;
            float extinctionCoeff = 0.01 * dens;
            cloud.a *= exp(-extinctionCoeff * marchStep);
            float sunIntensityAtSurface = clamp(0.2 - dens, 0.0, 1.0);
            vec3 sunLight = lighting * czm_lightColor * sunIntensityAtSurface * czm_lightColor.z;
            vec3 ambientSun = czm_lightColor * sunIntensityAtSurface * czm_lightColor.z * isotropic();
            vec3 skyAmbientLight = (skyAmbientColor * czm_lightColor.z + ambientSun);
            vec3 groundAmbientLight = (groundAmbientColor * czm_lightColor.z * 0.5 + ambientSun);
            vec3 ambientLight = mix(groundAmbientLight, skyAmbientLight, heightRatio);
            vec3 stepScattering = scatteringCoeff * marchStep * (sunScatteringPhase * sunLight + ambientScatteringPhase * ambientLight);
            cloud.rgb += cloud.a * stepScattering;

            if(cloud.a < 0.01) {
                cloud.a = 0.0;
                break;
            }

            if(distanceToFirstCloud == 0.0) {
                distanceToFirstCloud = distance;
            }
        } else {
            if(stepsBeforeExitingCloud > 0.0) {
                stepsBeforeExitingCloud--;
            } else {
                inCloud = false;
            }
        }

        distance += marchStep;

        if(distance > tmax) {
            if(rayComplete == true) {
                break;
            } else {
                rayComplete = true;
                distance = tmax;
            }
        }
    }

    vec4 atmosphereAtDistance = calculate_scattering(czm_viewerPositionWC, dir, distanceToFirstCloud, light_dir) * 0.2; // account for tone mapping
    cloud.rgb = cloud.rgb * (1.0 - atmosphereAtDistance.a) + atmosphereAtDistance.rgb;
    cloud.a = (1.0 - cloud.a);
    return cloud;
}

void main() {
    vec4 color = vec4(0.0);
    if(cloudCover < 0.1) {
        out_FragColor = color;
        return;
    }

    vec4 rawDepthColor = texture(czm_globeDepthTexture, v_textureCoordinates);

  #if !defined(GL_EXT_frag_depth)
    float depth = rawDepthColor.r; // depth packing algo appears to be buggy on mobile so only use the most significant element for now
    #else
    float depth = czm_unpackDepth(rawDepthColor);
  #endif

    if(depth == 0.0) {
        depth = 1.0;
    }

  #ifdef VOLUMETRIC_CLOUDS
    vec4 positionEC = czm_windowToEyeCoordinates(gl_FragCoord.xy, depth);
    vec4 worldCoordinate = czm_inverseView * positionEC;
    vec3 vWorldPosition = worldCoordinate.xyz / worldCoordinate.w;
    vec3 posToEye = vWorldPosition - czm_viewerPositionWC;
    vec3 direction = normalize(posToEye);
    vec3 lightDirection = normalize(czm_sunPositionWC);
    float distance = length(posToEye);

    if(depth == 1.0) {
        distance = CLOUDS_MAX_VIEWING_DISTANCE;
    }
    vec3 wind = windVector * czm_frameNumber * windSpeedRatio;

    color = calculate_clouds(czm_viewerPositionWC, // the position of the camera
    direction, // the camera vector (ray direction of this pixel)
    distance, // max dist, essentially the scene depth
    lightDirection, // light direction
    wind);
  #endif
    out_FragColor = color;
}