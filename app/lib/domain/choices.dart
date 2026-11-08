/// Cada opción es el aviso completo.
/// En la pantalla basta un toque para elegirla: no hay un segundo menú de tipo.
class PublishChoice {
  const PublishChoice({
    required this.id,
    required this.intent,
    required this.label,
    required this.group,
    this.helpType,
  });

  final String id;
  final String intent;
  final String? helpType;
  final String label;
  final String group;
}

const kPublishChoices = <PublishChoice>[
  PublishChoice(id: 'pido-herramienta', intent: 'pido_ayuda', helpType: 'herramienta', label: 'Pido una herramienta', group: 'favor'),
  PublishChoice(id: 'presto-herramienta', intent: 'ofrezco_ayuda', helpType: 'herramienta', label: 'Presto una herramienta', group: 'favor'),
  PublishChoice(id: 'pido-temporal', intent: 'pido_ayuda', helpType: 'ayuda_temporal', label: 'Pido ayuda temporal', group: 'favor'),
  PublishChoice(id: 'ofrezco-temporal', intent: 'ofrezco_ayuda', helpType: 'ayuda_temporal', label: 'Ofrezco ayuda temporal', group: 'favor'),
  PublishChoice(id: 'pido-donacion', intent: 'pido_ayuda', helpType: 'donacion', label: 'Pido una donación', group: 'favor'),
  PublishChoice(id: 'ofrezco-donacion', intent: 'ofrezco_ayuda', helpType: 'donacion', label: 'Ofrezco una donación', group: 'favor'),
  PublishChoice(id: 'pido-habilidad', intent: 'pido_ayuda', helpType: 'habilidad', label: 'Pido una habilidad', group: 'favor'),
  PublishChoice(id: 'ofrezco-habilidad', intent: 'ofrezco_ayuda', helpType: 'habilidad', label: 'Ofrezco una habilidad', group: 'favor'),
  PublishChoice(id: 'pido-movilidad', intent: 'pido_ayuda', helpType: 'movilidad', label: 'Pido movilidad', group: 'favor'),
  PublishChoice(id: 'ofrezco-movilidad', intent: 'ofrezco_ayuda', helpType: 'movilidad', label: 'Ofrezco movilidad', group: 'favor'),
  PublishChoice(id: 'oficio', intent: 'servicio', label: 'Ofrezco un oficio', group: 'directorio'),
  PublishChoice(id: 'producto', intent: 'producto', label: 'Ofrezco un producto', group: 'directorio'),
  PublishChoice(id: 'persona', intent: 'emergencia_persona', label: 'Emergencia de una persona', group: 'emergencia'),
  PublishChoice(id: 'cuadra', intent: 'emergencia_cuadra', label: 'Emergencia de una cuadra', group: 'emergencia'),
  PublishChoice(id: 'recurso', intent: 'emergencia_recurso', label: 'Recurso para la emergencia', group: 'emergencia'),
  PublishChoice(id: 'grupo', intent: 'grupo_apoyo', label: 'Grupo de apoyo', group: 'emergencia'),
];

const kDefaultPublishChoice = 'pido-herramienta';

PublishChoice publishChoice(String id) {
  for (final choice in kPublishChoices) {
    if (choice.id == id) return choice;
  }
  return kPublishChoices.first;
}
