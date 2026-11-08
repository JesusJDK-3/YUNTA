import { describe, expect, it } from "vitest";
import { YuntaError } from "./errors";
import {
  assertPublicText,
  distanceLabel,
  haversineMeters,
  nearestZone,
  parsePhone,
  parsePublish,
  publicRating,
  specFromIntent,
  ZONE_CENTERS,
} from "./rules";

describe("specFromIntent", () => {
  it("deja el oficio como anuncio y la muleta como caso entre dos", () => {
    const oficio = specFromIntent("servicio");
    expect(oficio.kind).toBe("anuncio");
    expect(oficio.authorRole).toBeNull();

    const muleta = specFromIntent("pido_ayuda", "herramienta");
    expect(muleta).toMatchObject({
      kind: "caso",
      coordinationMode: "individual",
      authorRole: "receptor",
    });

    const cuadra = specFromIntent("emergencia_cuadra");
    expect(cuadra).toMatchObject({
      coordinationMode: "grupal",
      authorRole: "participante",
    });

    const persona = specFromIntent("emergencia_persona");
    expect(persona.coordinationMode).toBe("individual");
  });
});

describe("distancia", () => {
  it("redondea y no dice 0 m", () => {
    expect(distanceLabel(40)).toBe("A menos de 100 m");
    expect(distanceLabel(240)).toBe("A unos 200 m");
    expect(distanceLabel(250)).toBe("A unos 300 m");
    expect(distanceLabel(null)).toBeNull();
  });

  it("separa Norte y Centro por más de 500 m", () => {
    const meters = haversineMeters(ZONE_CENTERS.norte, ZONE_CENTERS.centro);
    expect(meters).toBeGreaterThan(500);
    expect(nearestZone(ZONE_CENTERS.norte.lat, ZONE_CENTERS.norte.lng)).toBe("norte");
  });
});

describe("validación", () => {
  it("rechaza un título corto y un teléfono imposible", () => {
    expect(() =>
      parsePublish({
        intent: "servicio",
        title: "ab",
        description: "oficio",
        clientRequestId: crypto.randomUUID(),
      }),
    ).toThrow(YuntaError);

    expect(parsePhone("987 654 321")).toBe("+987654321");
    expect(() => parsePhone("12")).toThrow(YuntaError);
  });

  it("no deja un celular ni una calle numerada en el muro", () => {
    expect(() => assertPublicText("Gasfiter", "Llámame al 987 654 321")).toThrow(YuntaError);
    expect(() => assertPublicText("Ayuda", "Estoy en calle Los Pinos 120")).toThrow(YuntaError);
    expect(() => assertPublicText("Baldes", "Hacen falta 2 baldes")).not.toThrow();
  });

  it("guarda el promedio solo desde la tercera nota", () => {
    expect(publicRating(2, 5).ratingAverage).toBeNull();
    expect(publicRating(3, 4.26).ratingAverage).toBe(4.3);
  });
});
