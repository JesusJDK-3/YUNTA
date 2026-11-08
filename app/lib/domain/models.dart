// Contratos que ve la interfaz.
// El punto geográfico no está en estos tipos: la pantalla recibe zona
// y una frase de distancia ya redondeada.

class ZoneOption {
  const ZoneOption(this.id, this.name);
  final String id;
  final String name;
}

const kZones = <ZoneOption>[
  ZoneOption('norte', 'Zona Norte'),
  ZoneOption('centro', 'Zona Centro'),
  ZoneOption('sur', 'Zona Sur'),
  ZoneOption('este', 'Zona Este'),
];

const kHelpTypes = <String>[
  'herramienta',
  'ayuda_temporal',
  'donacion',
  'habilidad',
  'movilidad',
];

const kIntents = <String>[
  'pido_ayuda',
  'ofrezco_ayuda',
  'producto',
  'servicio',
  'emergencia_persona',
  'emergencia_cuadra',
  'emergencia_recurso',
  'grupo_apoyo',
];

class Session {
  const Session({
    required this.userId,
    required this.displayName,
    required this.zoneId,
    required this.zoneName,
  });

  final String userId;
  final String displayName;
  final String zoneId;
  final String zoneName;
}

class FeedItem {
  const FeedItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.zoneId,
    required this.zoneName,
    required this.areaLabel,
    required this.distanceLabel,
    required this.coordinationMode,
    required this.status,
    required this.recommendationCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.authorId,
    required this.authorName,
    required this.sourceAnuncioId,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String category;
  final String type;
  final String title;
  final String description;
  final String zoneId;
  final String zoneName;
  final String areaLabel;

  /// Frase ya redondeada. Nunca metros exactos.
  final String? distanceLabel;
  final String? coordinationMode;
  final String status;
  final int recommendationCount;

  /// Presente solo cuando el prestador acumula 3 valoraciones o más.
  final double? ratingAverage;
  final int ratingCount;
  final String authorId;
  final String authorName;
  final String? sourceAnuncioId;
  final String createdAt;
}

class MemberView {
  const MemberView({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.status,
  });

  final String userId;
  final String displayName;
  final String role;
  final String status;
}

class MessageView {
  const MessageView({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.pending = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String body;
  final String createdAt;

  /// Escrito sin señal. Se envía cuando vuelve la red.
  final bool pending;
}

class RatingView {
  const RatingView({required this.score, required this.comment});
  final int score;
  final String comment;
}

class Detail {
  const Detail({
    required this.item,
    required this.members,
    required this.pending,
    required this.messages,
    required this.myRole,
    required this.myStatus,
    required this.isAuthor,
    required this.chatOpen,
    required this.canSend,
    required this.canRecommend,
    required this.alreadyRecommended,
    required this.canOfferHelp,
    required this.canRequestHelp,
    required this.canJoinGroup,
    required this.canResolve,
    required this.canCancel,
    required this.canReopen,
    required this.canSharePhone,
    required this.canEdit,
    required this.canRetire,
    required this.canRate,
    required this.myRating,
    this.offline = false,
  });

  final FeedItem item;
  final List<MemberView> members;
  final List<MemberView> pending;
  final List<MessageView> messages;
  final String? myRole;
  final String? myStatus;
  final bool isAuthor;
  final bool chatOpen;
  final bool canSend;
  final bool canRecommend;
  final bool alreadyRecommended;
  final bool canOfferHelp;
  final bool canRequestHelp;
  final bool canJoinGroup;
  final bool canResolve;
  final bool canCancel;
  final bool canReopen;
  final bool canSharePhone;
  final bool canEdit;
  final bool canRetire;
  final bool canRate;
  final RatingView? myRating;

  /// La ficha salió de la copia guardada en el celular.
  final bool offline;

  Detail copyWith({List<MessageView>? messages, bool? offline}) {
    return Detail(
      item: item,
      members: members,
      pending: pending,
      messages: messages ?? this.messages,
      myRole: myRole,
      myStatus: myStatus,
      isAuthor: isAuthor,
      chatOpen: chatOpen,
      canSend: canSend,
      canRecommend: canRecommend,
      alreadyRecommended: alreadyRecommended,
      canOfferHelp: canOfferHelp,
      canRequestHelp: canRequestHelp,
      canJoinGroup: canJoinGroup,
      canResolve: canResolve,
      canCancel: canCancel,
      canReopen: canReopen,
      canSharePhone: canSharePhone,
      canEdit: canEdit,
      canRetire: canRetire,
      canRate: canRate,
      myRating: myRating,
      offline: offline ?? this.offline,
    );
  }
}

class PublishInput {
  const PublishInput({
    required this.intent,
    required this.title,
    required this.description,
    required this.clientRequestId,
    this.helpType,
    this.areaLabel,
    this.lat,
    this.lng,
  });

  final String intent;
  final String? helpType;
  final String title;
  final String description;
  final String? areaLabel;

  /// Punto aproximado. El servidor lo guarda y no lo devuelve.
  final double? lat;
  final double? lng;
  final String clientRequestId;

  Map<String, dynamic> toJson() => {
        'intent': intent,
        'helpType': helpType,
        'title': title,
        'description': description,
        'areaLabel': areaLabel,
        'lat': lat,
        'lng': lng,
        'clientRequestId': clientRequestId,
      };

  factory PublishInput.fromJson(Map<String, dynamic> json) {
    return PublishInput(
      intent: json['intent'] as String,
      helpType: json['helpType'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      areaLabel: json['areaLabel'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      clientRequestId: json['clientRequestId'] as String,
    );
  }
}

class BlockView {
  const BlockView({required this.userId, required this.displayName});
  final String userId;
  final String displayName;
}

class FeedResult {
  const FeedResult({
    required this.items,
    required this.needsLocation,
    this.offline = false,
  });

  final List<FeedItem> items;

  /// Falta el GPS: el muro de emergencias solo muestra grupos de apoyo.
  final bool needsLocation;

  /// La lista salió de la copia guardada en el celular.
  final bool offline;
}

class ViewerPoint {
  const ViewerPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class CreatedRef {
  const CreatedRef({required this.id, required this.deduped});
  final String id;
  final bool deduped;
}
