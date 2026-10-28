import 'package:flutter/material.dart';
import '../widgets/kaisa_resident_design.dart';

class KaisaProfileAvatar extends StatelessWidget {
  const KaisaProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 38,
  });
  final String name;
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFE5F2E9),
    backgroundImage: url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
    child: url != null && url!.isNotEmpty
        ? null
        : Text(
            name.trim().isEmpty
                ? '?'
                : name.trim().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: KaisaResidentDesign.forest,
              fontWeight: FontWeight.w900,
              fontSize: radius * .7,
            ),
          ),
  );
}

class KaisaProfilePostCard extends StatelessWidget {
  const KaisaProfilePostCard({
    super.key,
    required this.post,
    required this.imageUrl,
  });
  final Map<String, dynamic> post;
  final String Function(String) imageUrl;
  @override
  Widget build(BuildContext context) {
    final images = (post['images'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final created = DateTime.tryParse('${post['created_at']}')?.toLocal();
    return KaisaResidentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_outlined,
                color: KaisaResidentDesign.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${post['category'] ?? 'Community'}',
                  style: const TextStyle(
                    color: KaisaResidentDesign.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (created != null)
                Text(
                  '${created.day}/${created.month}/${created.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: KaisaResidentDesign.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${post['body'] ?? ''}',
            style: const TextStyle(
              color: KaisaResidentDesign.ink,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final path in images.take(2))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl(path),
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => const SizedBox(
                            height: 150,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '${post['likes'] ?? 0} likes  •  ${post['comments'] ?? 0} comments',
            style: const TextStyle(
              color: KaisaResidentDesign.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
