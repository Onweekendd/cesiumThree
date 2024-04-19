/**
 * 把a限制在b和c之间
 * @param a
 * @param b
 * @param c
 * @returns
 */
export function clamp(a: number, b: number, c: number) {
  return a > c ? c : a < b ? b : a;
}

export function createFragmentShaderPrefix(
  quality: number,
  volumetricClouds: boolean
) {
  return (
    "#define ADVANCED_ATMOSPHERE\n" +
    (volumetricClouds ? "#define VOLUMETRIC_CLOUDS\n" : "") +
    `#define QUALITY_${quality}\n`
  );
}
