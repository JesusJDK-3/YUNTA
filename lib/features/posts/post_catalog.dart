import 'package:flutter/material.dart';

enum PostCategory { help, productsServices, emergency }

extension PostCategoryLabels on PostCategory {
  String get databaseValue => switch (this) {
    PostCategory.help => 'help',
    PostCategory.productsServices => 'products_services',
    PostCategory.emergency => 'emergency',
  };

  String get label => switch (this) {
    PostCategory.help => 'Ayuda',
    PostCategory.productsServices => 'Productos y servicios',
    PostCategory.emergency => 'Emergencias',
  };

  IconData get icon => switch (this) {
    PostCategory.help => Icons.volunteer_activism_outlined,
    PostCategory.productsServices => Icons.storefront_outlined,
    PostCategory.emergency => Icons.warning_amber_rounded,
  };
}

class PostTypeDefinition {
  const PostTypeDefinition({
    required this.value,
    required this.category,
    required this.label,
    required this.icon,
    this.groupOnly = false,
    this.publishLabel,
  });

  final String value;
  final PostCategory category;
  final String label;
  final IconData icon;
  final bool groupOnly;
  final String? publishLabel;
}

const postTypes = <PostTypeDefinition>[
  PostTypeDefinition(
    value: 'help_request',
    category: PostCategory.help,
    label: 'Necesito ayuda',
    icon: Icons.handshake_outlined,
    publishLabel: 'Necesito ayuda',
  ),
  PostTypeDefinition(
    value: 'help_offer',
    category: PostCategory.help,
    label: 'Puedo ayudar',
    icon: Icons.volunteer_activism_outlined,
  ),
  PostTypeDefinition(
    value: 'product',
    category: PostCategory.productsServices,
    label: 'Producto',
    icon: Icons.inventory_2_outlined,
  ),
  PostTypeDefinition(
    value: 'service',
    category: PostCategory.productsServices,
    label: 'Servicio',
    icon: Icons.handyman_outlined,
    publishLabel: 'Servicio',
  ),
  PostTypeDefinition(
    value: 'urgent_request',
    category: PostCategory.emergency,
    label: 'Necesito apoyo urgente',
    icon: Icons.warning_amber_rounded,
    groupOnly: true,
    publishLabel: 'Aviso de emergencia',
  ),
  PostTypeDefinition(
    value: 'resource_available',
    category: PostCategory.emergency,
    label: 'Tengo un recurso disponible',
    icon: Icons.inventory_outlined,
  ),
  PostTypeDefinition(
    value: 'support_group_available',
    category: PostCategory.emergency,
    label: 'Grupo de apoyo disponible',
    icon: Icons.groups_outlined,
    groupOnly: true,
  ),
];

final publishablePostTypes = postTypes
    .where((type) => type.publishLabel != null)
    .toList(growable: false);

PostTypeDefinition? postTypeFor(String value) {
  for (final type in postTypes) {
    if (type.value == value) return type;
  }
  return null;
}

String postStatusLabel(String status) => switch (status) {
  'open' => 'Abierto',
  'coordinating' => 'En coordinación',
  'resolved' => 'Resuelto',
  'cancelled' => 'Retirado',
  _ => 'Estado no disponible',
};
