class RegistryOrganization {
  final String id;
  String name;
  String category;
  String description;
  String email;
  String registryReference;
  String adminEmail;
  String status;

  RegistryOrganization({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.email,
    required this.registryReference,
    this.adminEmail = '',
    this.status = 'Active',
  });

  RegistryOrganization copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? email,
    String? registryReference,
    String? adminEmail,
    String? status,
  }) {
    return RegistryOrganization(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      email: email ?? this.email,
      registryReference: registryReference ?? this.registryReference,
      adminEmail: adminEmail ?? this.adminEmail,
      status: status ?? this.status,
    );
  }
}
