import { describe, expect, it } from "vitest";
import { splitEmergencyBoard } from "./boards";
import { HELP_TYPES, type FeedItem } from "./types";
import { PUBLISH_CHOICES } from "./publish-choices";

function item(partial: Pick<FeedItem, "id" | "category" | "type" | "title">): FeedItem {
  return {
    kind: partial.category === "servicio" || partial.category === "producto" ? "anuncio" : "caso",
    description: "",
    zoneId: "centro",
    zoneName: "Zona Centro",
    areaLabel: "Zona Centro",
    distanceLabel: "A unos 200 m",
    coordinationMode: "grupal",
    status: "abierto",
    recommendationCount: 0,
    ratingAverage: null,
    ratingCount: 0,
    authorId: "11111111-1111-4111-8111-111111111111",
    authorName: "Ana",
    sourceAnuncioId: null,
    createdAt: "2026-11-08T00:00:00.000Z",
    ...partial,
  };
}

describe("splitEmergencyBoard", () => {
  it("separa el tablero humanitario, la economía solidaria y los grupos", () => {
    const boards = splitEmergencyBoard([
      item({ id: "11111111-1111-4111-8111-111111111111", category: "emergencia", type: "persona", title: "Persona" }),
      item({ id: "22222222-2222-4222-8222-222222222222", category: "emergencia", type: "cuadra", title: "Cuadra" }),
      item({ id: "33333333-3333-4333-8333-333333333333", category: "emergencia", type: "recurso", title: "Agua" }),
      item({ id: "44444444-4444-4444-8444-444444444444", category: "grupo_de_apoyo", type: "grupo_de_apoyo", title: "Posta" }),
    ]);
    expect(boards.humanitario.map((row) => row.title)).toEqual(["Persona", "Cuadra"]);
    expect(boards.solidaria.map((row) => row.title)).toEqual(["Agua"]);
    expect(boards.apoyo.map((row) => row.title)).toEqual(["Posta"]);
  });
});

describe("PUBLISH_CHOICES", () => {
  it("deja cada aviso en una sola opción, sin un segundo menú", () => {
    for (const type of HELP_TYPES) {
      expect(PUBLISH_CHOICES.some((choice) => choice.intent === "pido_ayuda" && choice.helpType === type)).toBe(true);
      expect(PUBLISH_CHOICES.some((choice) => choice.intent === "ofrezco_ayuda" && choice.helpType === type)).toBe(true);
    }
    for (const intent of ["servicio", "producto", "emergencia_persona", "emergencia_cuadra", "emergencia_recurso", "grupo_apoyo"] as const) {
      expect(PUBLISH_CHOICES.filter((choice) => choice.intent === intent)).toHaveLength(1);
    }
  });
});
