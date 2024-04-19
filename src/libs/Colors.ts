import { Color } from "mars3d-cesium";
import { clamp } from "./Tool";

const Colors = {
  pixelToHex(a: [number, number, number, number?]): string {
    return Color.fromBytes(a[0], a[1], a[2], a[3] || 255).toCssHexString();
  },
  bytesToHex(a: number, b: number, c: number, d?: number): string {
    return Color.fromBytes(a, b, c, d || 255).toCssHexString();
  },
  compareRGBBytes(a: number[], b: number[]): boolean {
    return a.every((c, d) => c === b[d]);
  },
  mix(a: Color, b: Color, c: number): Color {
    return Color.lerp(a, b, c, new Color());
  },
  mixArray(a: Color[], b: number): Color {
    const c = a.length - 1;
    b *= c;
    const d = Math.floor(b);
    const e = clamp(Math.floor(b + 1), 0, c);
    return Color.lerp(a[d], a[e], b - d, new Color());
  },
};

export default Colors;
